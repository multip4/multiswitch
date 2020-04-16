//
// Copyright (c) 2017 Stephen Ibanez
// All rights reserved.
//
// This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
// as part of the DARPA MRC research programme.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//
// for wave debugging,
// parse 1 field of ehternet header,
// and change at pipe line.

#include <core.p4>
#include <sume_switch.p4>

/*
  Switch Calculator:
  P4 program to use switch as a calculator and key-value lookup engine
 */

typedef bit<48> EthAddr_t; 
typedef bit<32> ipv4_addr_t;


#define CLASS_WIDTH 5 // 32 
#define PORT_WIDTH 8 // port maximum support 8

// standard Ethernet header
header Ethernet_h { 
    EthAddr_t dstAddr; 
    EthAddr_t srcAddr; 
}

header Calc_h {
    bit<CLASS_WIDTH> class_id; //flow_id
}


// List of all recognized headers
struct Parsed_packet { 
    Ethernet_h ethernet; 
    Calc_h calc;
}

// user defined metadata: can be used to share information between
// TopParser, TopPipe, and TopDeparser 
struct user_metadata_t {
    bit<8>  unused;
}

// digest_data, MUST be 256 bits
struct digest_data_t {
    bit<256> unused;
}


// Parser Implementation
@Xilinx_MaxPacketRegion(1024)
parser TopParser(packet_in b, 
                 out Parsed_packet p, 
                 out user_metadata_t user_metadata,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {
    state start {
        b.extract(p.ethernet);
        user_metadata.unused = 0;
        digest_data.unused = 0;
        transition accept; 
    }

}

// match-action pipeline
control TopPipe(inout Parsed_packet p,
                inout user_metadata_t user_metadata, 
                inout digest_data_t digest_data,
                inout sume_metadata_t sume_metadata) {


    action set_calc(bit<CLASS_WIDTH> d1, port_t port){
        p.calc.setValid();
        p.calc.class_id = d1;
        sume_metadata.dst_port = port;
    }


    table table_calc {
        key = { p.ethernet.dstAddr: exact; }
        actions = {
            set_calc;
        }
        size = 64;
    }

    apply {
         table_calc.apply();
         
         sume_metadata.pifo_info.pifo_valid = 1;
         sume_metadata.pifo_info.pifo_rank = 10;
         sume_metadata.pifo_info.pifo_field = 0;

        //sume_metadata.pifo_info = 3222;


         if (p.calc.class_id == 6 || p.calc.class_id == 7 || p.calc.class_id == 8 || p.calc.class_id == 9 || p.calc.class_id == 10)
            sume_metadata.drop = 1;
    }
}

// Deparser Implementation
@Xilinx_MaxPacketRegion(1024)
control TopDeparser(packet_out b,
                    in Parsed_packet p,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data,
                    inout sume_metadata_t sume_metadata) { 
    apply {
        b.emit(p.ethernet); 
    }
}

// Instantiate the switch
SimpleSumeSwitch(TopParser(), TopPipe(), TopDeparser()) main;
`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Zhenguo Cui
// 
// Create Date: 08/27/2019 01:21:10 PM
// Design Name: 
// Module Name: scheduler_top_v0_1
// Project Name: MultiP4
// Target Devices: NetFPGA SUME
// Tool Versions: Vivado2018.2, SDNet 2018.2
// Description: PIFO Scheduler for Netfpga SUME, replace original output queue.
//  
// Dependencies: 
//  input signal from PIPELINE,
//  output signal to nf_10g_etherent... modules.
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module scheduler_top_v0_1
    #(
    // parameters from original output_queue.v
    // Master AXI Stream Data Width
    parameter DATA_WIDTH=256,
    parameter PKT_BUFFER_WIDTH = 289,
    parameter C_S_AXIS_TUSER_WIDTH=160, // 128 + pifo width(32)
    parameter C_M_AXIS_TUSER_WIDTH=128,
    //parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter NUM_QUEUES=5,
//    parameter BUFFER_INDEX_WIDTH = 12,  // calculated by log2 function
    
    // AXI Registers Data Width
    parameter C_S_AXI_DATA_WIDTH    = 32,          
    parameter C_S_AXI_ADDR_WIDTH    = 32,
//    parameter CPU_BUFFER_CALL_INDEX_WIDTH = 12,
              
    parameter C_BASEADDR            = 32'h00000000,

    // SI
    parameter QUEUE_DEPTH_BITS = 16,
    // end for original parameter.
    
    // parameters for scheduler_top.
    parameter BUFFER_WORD_DEPTH = 512,
    parameter PIFO_CALENDAR_DEPTH = 32,  // scale down to test bit simulation.
    parameter PIFO_INFO_LENGTH = 32,
    parameter BUFFER_OUTPUT_SYNC=0,
    parameter CPU_EQ_AGENT_ADDR = 8
    )
    (
    // Part 1: System side signals
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    // Slave Stream Ports (interface to data path)
     input [DATA_WIDTH - 1:0]                    s_axis_tdata,
     input [(DATA_WIDTH / 8) - 1:0]              s_axis_tkeep,
     input [C_S_AXIS_TUSER_WIDTH-1:0]            s_axis_tuser,
     input                                       s_axis_tvalid,
     input                                       s_axis_tlast,
     output                                      s_axis_tready,   
    
    // Master Stream Ports (interface to TX queues)
     input                                       m_axis_0_tready,
     output [DATA_WIDTH - 1:0]                   m_axis_0_tdata,
     output [(DATA_WIDTH / 8) - 1:0]             m_axis_0_tkeep,
     output [C_M_AXIS_TUSER_WIDTH-1:0]           m_axis_0_tuser,
     output [PIFO_INFO_LENGTH-1:0]               m_axis_0_tpifo,
     output                                      m_axis_0_tvalid,
     output                                      m_axis_0_tlast,
    
    input                                       m_axis_1_tready,
    output [DATA_WIDTH - 1:0]                   m_axis_1_tdata,
    output [(DATA_WIDTH / 8) - 1:0]             m_axis_1_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]           m_axis_1_tuser,
    output [PIFO_INFO_LENGTH-1:0]               m_axis_1_tpifo,
    output                                      m_axis_1_tvalid,
    output                                      m_axis_1_tlast,

    input                                       m_axis_2_tready,
    output [DATA_WIDTH - 1:0]                   m_axis_2_tdata,
    output [(DATA_WIDTH / 8) - 1:0]             m_axis_2_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]           m_axis_2_tuser,
    output [PIFO_INFO_LENGTH-1:0]               m_axis_2_tpifo,
    output                                      m_axis_2_tvalid,
    output                                      m_axis_2_tlast,

    input                                       m_axis_3_tready,
    output [DATA_WIDTH - 1:0]                   m_axis_3_tdata,
    output [((DATA_WIDTH / 8)) - 1:0]           m_axis_3_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]           m_axis_3_tuser,
    output [PIFO_INFO_LENGTH-1:0]               m_axis_3_tpifo,
    output                                      m_axis_3_tvalid,
    output                                      m_axis_3_tlast,

    input                                       m_axis_4_tready,
    output [DATA_WIDTH - 1:0]                   m_axis_4_tdata,
    output [(DATA_WIDTH / 8) - 1:0]             m_axis_4_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]           m_axis_4_tuser,
    output [PIFO_INFO_LENGTH-1:0]               m_axis_4_tpifo,
    output                                      m_axis_4_tvalid,
    output                                      m_axis_4_tlast,

    // stats
     output [QUEUE_DEPTH_BITS-1:0] nf0_q_size,
     output [QUEUE_DEPTH_BITS-1:0] nf1_q_size,
     output [QUEUE_DEPTH_BITS-1:0] nf2_q_size,
     output [QUEUE_DEPTH_BITS-1:0] nf3_q_size,
     output [QUEUE_DEPTH_BITS-1:0] dma_q_size,

//    output reg  [C_S_AXI_DATA_WIDTH-1:0] bytes_stored,
//    output reg  [NUM_QUEUES-1:0]         pkt_stored,

//    output [C_S_AXI_DATA_WIDTH-1:0]  bytes_removed_0,
//    output [C_S_AXI_DATA_WIDTH-1:0]  bytes_removed_1,
//    output [C_S_AXI_DATA_WIDTH-1:0]  bytes_removed_2,
//    output [C_S_AXI_DATA_WIDTH-1:0]  bytes_removed_3,
//    output [C_S_AXI_DATA_WIDTH-1:0]  bytes_removed_4,
//    output [C_S_AXI_DATA_WIDTH-1:0]  pkt_removed_0,
//    output [C_S_AXI_DATA_WIDTH-1:0]  pkt_removed_1,
//    output [C_S_AXI_DATA_WIDTH-1:0]  pkt_removed_2,
//    output [C_S_AXI_DATA_WIDTH-1:0]  pkt_removed_3,
//    output [C_S_AXI_DATA_WIDTH-1:0]  pkt_removed_4,

// Slave AXI Ports
    input                                     S_AXI_ACLK,
    input                                     S_AXI_ARESETN,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
    input                                     S_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB,
    input                                     S_AXI_WVALID,
    input                                     S_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
    input                                     S_AXI_ARVALID,
    input                                     S_AXI_RREADY,
    output                                    S_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
    output     [1 : 0]                        S_AXI_RRESP,
    output                                    S_AXI_RVALID,
    output                                    S_AXI_WREADY,
    output     [1 :0]                         S_AXI_BRESP,
    output                                    S_AXI_BVALID,
    output                                    S_AXI_AWREADY

//    output reg [C_S_AXI_DATA_WIDTH-1:0]  bytes_dropped,
//    output reg [NUM_QUEUES-1:0]          pkt_dropped
    );
    
    
    function integer log2;
       input integer number;
       begin
          log2=0;
          while(2**log2<number) begin
             log2=log2+1;
          end
       end
    endfunction // log2
    
    localparam BUFFER_INDEX_WIDTH = log2(BUFFER_WORD_DEPTH);
    localparam CPU_BUFFER_CALL_INDEX_WIDTH = log2(BUFFER_WORD_DEPTH);
    localparam PIFO_INDEX_WIDTH = log2(PIFO_CALENDAR_DEPTH);    
    
    
    
     wire [NUM_QUEUES-1:0]               w_buffer_almost_full_bit_array; 
     wire [NUM_QUEUES-1:0]               w_pifo_full_bit_array;
     wire [NUM_QUEUES-1:0]               w_buffer_write_en_bit_array; 
     wire [NUM_QUEUES-1:0]               w_pifo_insert_en_bit_array; 
    
  
        


    // read wire between cpu_sub and output queue module
    wire [CPU_BUFFER_CALL_INDEX_WIDTH-1 : 0]     w_cpu2ip_read_pkt_buffer_req_addr;
    wire [NUM_QUEUES-1:0]               w_cpu2ip_read_pkt_buffer_req_valid;
    wire [PKT_BUFFER_WIDTH-1:0]         w_ip2cpu_read_pkt_buffer_resp_value;
    wire [NUM_QUEUES-1:0]               w_ip2cpu_read_pkt_buffer_resp_valid;
    
    wire [CPU_BUFFER_CALL_INDEX_WIDTH-1 : 0]     w_cpu2ip_read_sume_buffer_req_addr;
    wire [NUM_QUEUES-1:0]               w_cpu2ip_read_sume_buffer_req_valid;  
    wire [C_M_AXIS_TUSER_WIDTH-1:0]     w_ip2cpu_read_sume_buffer_resp_value;  
    wire [NUM_QUEUES-1:0]               w_ip2cpu_read_sume_buffer_resp_valid;  
                                         
    wire [CPU_BUFFER_CALL_INDEX_WIDTH-1 : 0]     w_cpu2ip_read_pifo_buffer_req_addr;    
    wire [NUM_QUEUES-1:0]               w_cpu2ip_read_pifo_buffer_req_valid;   
    wire [PIFO_INFO_LENGTH-1:0]         w_ip2cpu_read_pifo_buffer_resp_value;  
    wire [NUM_QUEUES-1:0]               w_ip2cpu_read_pifo_buffer_resp_valid;  
                                         
    wire [PIFO_INDEX_WIDTH-1 : 0]     w_cpu2ip_read_pifo_calendar_req_addr;  
    wire [NUM_QUEUES-1:0]               w_cpu2ip_read_pifo_calendar_req_valid; 
    wire [PIFO_INFO_LENGTH-1:0]         w_ip2cpu_read_pifo_calendar_resp_value;
    wire [NUM_QUEUES-1:0]               w_ip2cpu_read_pifo_calendar_resp_valid;
                                         
    // write wire between cpu_sub and output queue module                                     
    wire [CPU_BUFFER_CALL_INDEX_WIDTH-1 : 0]     w_cpu2ip_write_pkt_buffer_req_addr;    
    wire [PKT_BUFFER_WIDTH-1:0]         w_cpu2ip_write_pkt_buffer_req_value;   
    wire [NUM_QUEUES-1:0]               w_cpu2ip_write_pkt_buffer_req_valid;   
    wire [NUM_QUEUES-1:0]               w_ip2cpu_write_pkt_buffer_resp_valid;  
                                         
    wire [CPU_BUFFER_CALL_INDEX_WIDTH-1 : 0]     w_cpu2ip_write_sume_buffer_req_addr;   
    wire [C_M_AXIS_TUSER_WIDTH-1:0]     w_cpu2ip_write_sume_buffer_req_value;  
    wire [NUM_QUEUES-1:0]               w_cpu2ip_write_sume_buffer_req_valid;  
    wire [NUM_QUEUES-1:0]               w_ip2cpu_write_sume_buffer_resp_valid; 
                                         
    wire [CPU_BUFFER_CALL_INDEX_WIDTH-1 : 0]     w_cpu2ip_write_pifo_buffer_req_addr;   
    wire [PIFO_INFO_LENGTH-1:0]         w_cpu2ip_write_pifo_buffer_req_value;  
    wire [NUM_QUEUES-1:0]               w_cpu2ip_write_pifo_buffer_req_valid;  
    wire [NUM_QUEUES-1:0]               w_ip2cpu_write_pifo_buffer_resp_valid; 
                                         
    wire [PIFO_INDEX_WIDTH-1 : 0]     w_cpu2ip_write_pifo_calendar_req_addr; 
    wire [PIFO_INFO_LENGTH-1:0]         w_cpu2ip_write_pifo_calendar_req_value;
    wire [NUM_QUEUES-1:0]               w_cpu2ip_write_pifo_calendar_req_valid;
    wire [NUM_QUEUES-1:0]               w_ip2cpu_write_pifo_calendar_resp_valid;

    reg [DATA_WIDTH - 1:0]                    s_axis_tdata_d1;
    reg [(DATA_WIDTH / 8) - 1:0]              s_axis_tkeep_d1;
    reg [C_S_AXIS_TUSER_WIDTH-1:0]            s_axis_tuser_d1;
    reg                                       s_axis_tvalid_d1;
    reg                                       s_axis_tlast_d1;

    reg [DATA_WIDTH - 1:0]                    s_axis_tdata_d2;
    reg [(DATA_WIDTH / 8) - 1:0]              s_axis_tkeep_d2;
    reg [C_S_AXIS_TUSER_WIDTH-1:0]            s_axis_tuser_d2;
    reg                                       s_axis_tvalid_d2;
    reg                                       s_axis_tlast_d2;

    reg [PIFO_INFO_LENGTH-1:0]         r_m_axis_0_tpifo;
    reg [PIFO_INFO_LENGTH-1:0]         r_m_axis_1_tpifo;
    reg [PIFO_INFO_LENGTH-1:0]         r_m_axis_2_tpifo;
    reg [PIFO_INFO_LENGTH-1:0]         r_m_axis_3_tpifo;
    reg [PIFO_INFO_LENGTH-1:0]         r_m_axis_4_tpifo;
            


    reg [NUM_QUEUES-1:0]               r_buffer_write_en_bit_array; 
    reg [NUM_QUEUES-1:0]               r_pifo_insert_en_bit_array; 

     wire [C_S_AXIS_TUSER_WIDTH-PIFO_INFO_LENGTH-1:0] w_sume_meta_d2;
     wire    [PIFO_INFO_LENGTH-1:0] w_pifo_info_d2;    

    wire [CPU_EQ_AGENT_ADDR-1:0] w_cpu2ip_read_stat_enqueue_agent_req_addr; 
    wire                          w_cpu2ip_read_stat_enqueue_agent_req_valid;
    wire [C_S_AXI_DATA_WIDTH-1:0] w_ip2cpu_read_stat_enqueue_agent_resp_value;
    wire                          w_ip2cpu_read_stat_enqueue_agent_resp_valid;
        
        
// enqueue agent handles real data(not delayed input data),
// to check whether drop or enqueue.

wire  [PIFO_INFO_LENGTH-1:0] w_pifo_info_d1 = s_axis_tuser_d1[C_S_AXIS_TUSER_WIDTH-1:C_S_AXIS_TUSER_WIDTH-PIFO_INFO_LENGTH];    
wire  [C_S_AXIS_TUSER_WIDTH-PIFO_INFO_LENGTH-1:0] w_sume_meta_d1 = s_axis_tuser_d1[C_S_AXIS_TUSER_WIDTH-PIFO_INFO_LENGTH-1:0];

    enqueue_agent_ip
    enqueue_agent_inst(
            // from/to pipeline
        .s_axis_tvalid(s_axis_tvalid_d1), 
        .s_axis_tready(s_axis_tready), //output signal.
        .s_axis_tuser(w_sume_meta_d1), // sume_meta.
        .s_axis_tpifo_valid(w_pifo_info_d1[PIFO_INFO_LENGTH-1]),//w_pifo_info[PIFO_INFO_LENGTH-1]
        .s_axis_tlast(s_axis_tlast_d1),
        .s_axis_tlast_f1(s_axis_tlast),
        
        // from each port queue status 
        .s_axis_buffer_almost_full(w_buffer_almost_full_bit_array),
        .s_axis_pifo_full(w_pifo_full_bit_array),
            
        .m_axis_ctl_pifo_in_en(w_pifo_insert_en_bit_array),
        .m_axis_ctl_buffer_wr_en(w_buffer_write_en_bit_array),
        
        // cpu read req/resp
        
        .s_axi_addr(w_cpu2ip_read_stat_enqueue_agent_req_addr),      
        .s_axi_req_valid(w_cpu2ip_read_stat_enqueue_agent_req_valid), 
                         
        .m_axi_data(w_ip2cpu_read_stat_enqueue_agent_resp_value),      
        .m_axi_resp_valid(w_ip2cpu_read_stat_enqueue_agent_resp_valid),        
        
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn)
    );

//    wire                        buffer_0_empty
    wire                        buffer_0_almost_full;
    wire                        pifo_0_full;
    wire [BUFFER_INDEX_WIDTH-1:0] buffer_0_queue_depth;
    
    wire [DATA_WIDTH - 1:0]                    w_axis_0_tdata_to_sss_output_queue_single;
    wire [(DATA_WIDTH / 8) - 1:0]              w_axis_0_tkeep_to_sss_output_queue_single;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]            w_axis_0_tuser_to_sss_output_queue_single;
    wire                                       w_axis_0_tvalid_to_sss_output_queue_single;
    wire                                       w_axis_0_tlast_to_sss_output_queue_single;
    wire                                       w_axis_0_tready_from_sss_output_queue_single;
    wire [PIFO_INFO_LENGTH-1:0]                w_axis_0_tpifo_next;
    pifo_output_queue_ip
    #(
    .BUFFER_ADDR_WIDTH(BUFFER_INDEX_WIDTH),  
    .BUFFER_WORD_DEPTH(BUFFER_WORD_DEPTH),
    .PIFO_WORD_DEPTH(PIFO_CALENDAR_DEPTH),
    .PIFO_ADDR_WIDTH(PIFO_INDEX_WIDTH),  
    .OUTPUT_SYNC(BUFFER_OUTPUT_SYNC)          
    )
    output_queue_inst_port0(
        .s_axis_tdata(s_axis_tdata_d2),
        .s_axis_tkeep(s_axis_tkeep_d2),
        .s_axis_tuser(w_sume_meta_d2),
        .s_axis_tpifo(w_pifo_info_d2),
        .s_axis_tvalid(s_axis_tvalid_d2),
        .s_axis_tlast(s_axis_tlast_d2),
        .s_axis_buffer_wr_en(r_buffer_write_en_bit_array[0]),
        .s_axis_pifo_insert_en(r_pifo_insert_en_bit_array[0]),
        .m_axis_tready(w_axis_0_tready_from_sss_output_queue_single),
        .m_axis_tvalid(w_axis_0_tvalid_to_sss_output_queue_single),
        .m_axis_tdata(w_axis_0_tdata_to_sss_output_queue_single),
        .m_axis_tkeep(w_axis_0_tkeep_to_sss_output_queue_single),
        .m_axis_tlast(w_axis_0_tlast_to_sss_output_queue_single),
        .m_axis_tuser(w_axis_0_tuser_to_sss_output_queue_single),
        .m_axis_tpifo(w_axis_0_tpifo_next),
        .m_is_buffer_almost_full(buffer_0_almost_full),
        .m_is_pifo_full(pifo_0_full),
        .m_buffer_counter(buffer_0_queue_depth),
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn),
        
        .cpu2ip_read_pkt_buffer_req_addr(w_cpu2ip_read_pkt_buffer_req_addr),     
        .cpu2ip_read_pkt_buffer_req_valid(w_cpu2ip_read_pkt_buffer_req_valid[0]),    
        .ip2cpu_read_pkt_buffer_resp_value(w_ip2cpu_read_pkt_buffer_resp_value),   
        .ip2cpu_read_pkt_buffer_resp_valid(w_ip2cpu_read_pkt_buffer_resp_valid[0]),   
                                                                                 
        .cpu2ip_read_sume_buffer_req_addr(w_cpu2ip_read_sume_buffer_req_addr),    
        .cpu2ip_read_sume_buffer_req_valid(w_cpu2ip_read_sume_buffer_req_valid[0]),   
        .ip2cpu_read_sume_buffer_resp_value(w_ip2cpu_read_sume_buffer_resp_value),  
        .ip2cpu_read_sume_buffer_resp_valid(w_ip2cpu_read_sume_buffer_resp_valid[0]),  
                                                                         
        .cpu2ip_read_pifo_buffer_req_addr(w_cpu2ip_read_pifo_buffer_req_addr),    
        .cpu2ip_read_pifo_buffer_req_valid(w_cpu2ip_read_pifo_buffer_req_valid[0]),   
        .ip2cpu_read_pifo_buffer_resp_value(w_ip2cpu_read_pifo_buffer_resp_value),  
        .ip2cpu_read_pifo_buffer_resp_valid(w_ip2cpu_read_pifo_buffer_resp_valid[0]),  
                                
        .cpu2ip_read_pifo_calendar_req_addr(w_cpu2ip_read_pifo_calendar_req_addr),  
        .cpu2ip_read_pifo_calendar_req_valid(w_cpu2ip_read_pifo_calendar_req_valid[0]), 
        .ip2cpu_read_pifo_calendar_resp_value(w_ip2cpu_read_pifo_calendar_resp_value),
        .ip2cpu_read_pifo_calendar_resp_valid(w_ip2cpu_read_pifo_calendar_resp_valid[0]),
                                                                              
        .cpu2ip_write_pkt_buffer_req_addr(w_cpu2ip_write_pkt_buffer_req_addr),    
        .cpu2ip_write_pkt_buffer_req_value(w_cpu2ip_write_pkt_buffer_req_value),   
        .cpu2ip_write_pkt_buffer_req_valid(w_cpu2ip_write_pkt_buffer_req_valid[0]),   
        .ip2cpu_write_pkt_buffer_resp_valid(w_ip2cpu_write_pkt_buffer_resp_valid[0]),  
                                                                                                                 
        .cpu2ip_write_sume_buffer_req_addr(w_cpu2ip_write_sume_buffer_req_addr),   
        .cpu2ip_write_sume_buffer_req_value(w_cpu2ip_write_sume_buffer_req_value),  
        .cpu2ip_write_sume_buffer_req_valid(w_cpu2ip_write_sume_buffer_req_valid[0]),  
        .ip2cpu_write_sume_buffer_resp_valid(w_ip2cpu_write_sume_buffer_resp_valid[0]), 
                                                                              
        .cpu2ip_write_pifo_buffer_req_addr(w_cpu2ip_write_pifo_buffer_req_addr),   
        .cpu2ip_write_pifo_buffer_req_value(w_cpu2ip_write_pifo_buffer_req_value),  
        .cpu2ip_write_pifo_buffer_req_valid(w_cpu2ip_write_pifo_buffer_req_valid[0]),  
        .ip2cpu_write_pifo_buffer_resp_valid(w_ip2cpu_write_pifo_buffer_resp_valid[0]), 
                                                                              
        .cpu2ip_write_pifo_calendar_req_addr(w_cpu2ip_write_pifo_calendar_req_addr), 
        .cpu2ip_write_pifo_calendar_req_value(w_cpu2ip_write_pifo_calendar_req_value),
        .cpu2ip_write_pifo_calendar_req_valid(w_cpu2ip_write_pifo_calendar_req_valid[0]),
        .ip2cpu_write_pifo_calendar_resp_valid(w_ip2cpu_write_pifo_calendar_resp_valid[0])
    );

    sss_output_queue_single_ip
    sss_output_queue_single_inst_0
    (
    .axis_aclk(axis_aclk),    
    .axis_resetn(axis_resetn),  
                             
    .s_axis_tdata(w_axis_0_tdata_to_sss_output_queue_single), 
    .s_axis_tkeep(w_axis_0_tkeep_to_sss_output_queue_single), 
    .s_axis_tuser(w_axis_0_tuser_to_sss_output_queue_single), 
    .s_axis_tvalid(w_axis_0_tvalid_to_sss_output_queue_single),
    .s_axis_tready(w_axis_0_tready_from_sss_output_queue_single),
    .s_axis_tlast(w_axis_0_tlast_to_sss_output_queue_single), 
                  
                  
    .m_axis_tdata(m_axis_0_tdata), 
    .m_axis_tkeep(m_axis_0_tkeep), 
    .m_axis_tuser(m_axis_0_tuser), 
    .m_axis_tvalid(m_axis_0_tvalid),
    .m_axis_tready(m_axis_0_tready),
    .m_axis_tlast(m_axis_0_tlast)   
    );


    
    wire                        buffer_1_almost_full;
    wire                        pifo_1_full;

    wire [BUFFER_INDEX_WIDTH-1:0] buffer_1_queue_depth;

    wire [DATA_WIDTH - 1:0]                    w_axis_1_tdata_to_sss_output_queue_single;
    wire [(DATA_WIDTH / 8) - 1:0]              w_axis_1_tkeep_to_sss_output_queue_single;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]            w_axis_1_tuser_to_sss_output_queue_single;
    wire                                       w_axis_1_tvalid_to_sss_output_queue_single;
    wire                                       w_axis_1_tlast_to_sss_output_queue_single;
    wire                                       w_axis_1_tready_from_sss_output_queue_single;
    wire [PIFO_INFO_LENGTH-1:0]                w_axis_1_tpifo_next;

    pifo_output_queue_ip
    #(
    .BUFFER_ADDR_WIDTH(BUFFER_INDEX_WIDTH),  
    .BUFFER_WORD_DEPTH(BUFFER_WORD_DEPTH),
    .PIFO_WORD_DEPTH(PIFO_CALENDAR_DEPTH),
    .PIFO_ADDR_WIDTH(PIFO_INDEX_WIDTH),  
    .OUTPUT_SYNC(BUFFER_OUTPUT_SYNC)          
    )
    output_queue_inst_port1(
        .s_axis_tdata(s_axis_tdata_d2),
        .s_axis_tkeep(s_axis_tkeep_d2),
        .s_axis_tuser(w_sume_meta_d2),
        .s_axis_tpifo(w_pifo_info_d2),
        .s_axis_tvalid(s_axis_tvalid_d2),
        .s_axis_tlast(s_axis_tlast_d2),
        .s_axis_buffer_wr_en(r_buffer_write_en_bit_array[1]),
        .s_axis_pifo_insert_en(r_pifo_insert_en_bit_array[1]),
        .m_axis_tready(w_axis_1_tready_from_sss_output_queue_single),
        .m_axis_tvalid(w_axis_1_tvalid_to_sss_output_queue_single),
        .m_axis_tdata(w_axis_1_tdata_to_sss_output_queue_single),
        .m_axis_tkeep(w_axis_1_tkeep_to_sss_output_queue_single),
        .m_axis_tlast(w_axis_1_tlast_to_sss_output_queue_single),
        .m_axis_tuser(w_axis_1_tuser_to_sss_output_queue_single),
        .m_axis_tpifo(w_axis_1_tpifo_next),
        .m_is_buffer_almost_full(buffer_1_almost_full),
        .m_is_pifo_full(pifo_1_full),
        .m_buffer_counter(buffer_1_queue_depth),
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn),
        
        
        .cpu2ip_read_pkt_buffer_req_addr(w_cpu2ip_read_pkt_buffer_req_addr),     
        .cpu2ip_read_pkt_buffer_req_valid(w_cpu2ip_read_pkt_buffer_req_valid[1]),    
//        .ip2cpu_read_pkt_buffer_resp_value(w_ip2cpu_read_pkt_buffer_resp_value),   
        .ip2cpu_read_pkt_buffer_resp_valid(w_ip2cpu_read_pkt_buffer_resp_valid[1]),   
                                                                                 
        .cpu2ip_read_sume_buffer_req_addr(w_cpu2ip_read_sume_buffer_req_addr),    
        .cpu2ip_read_sume_buffer_req_valid(w_cpu2ip_read_sume_buffer_req_valid[1]),   
//        .ip2cpu_read_sume_buffer_resp_value(w_ip2cpu_read_sume_buffer_resp_value),  
        .ip2cpu_read_sume_buffer_resp_valid(w_ip2cpu_read_sume_buffer_resp_valid[1]),  
                                                                         
        .cpu2ip_read_pifo_buffer_req_addr(w_cpu2ip_read_pifo_buffer_req_addr),    
        .cpu2ip_read_pifo_buffer_req_valid(w_cpu2ip_read_pifo_buffer_req_valid[1]),   
//        .ip2cpu_read_pifo_buffer_resp_value(w_ip2cpu_read_pifo_buffer_resp_value),  
        .ip2cpu_read_pifo_buffer_resp_valid(w_ip2cpu_read_pifo_buffer_resp_valid[1]),  
                                
        .cpu2ip_read_pifo_calendar_req_addr(w_cpu2ip_read_pifo_calendar_req_addr),  
        .cpu2ip_read_pifo_calendar_req_valid(w_cpu2ip_read_pifo_calendar_req_valid[1]), 
//        .ip2cpu_read_pifo_calendar_resp_value(w_ip2cpu_read_pifo_calendar_resp_value),
        .ip2cpu_read_pifo_calendar_resp_valid(w_ip2cpu_read_pifo_calendar_resp_valid[1]),
                                                                              
        .cpu2ip_write_pkt_buffer_req_addr(w_cpu2ip_write_pkt_buffer_req_addr),    
        .cpu2ip_write_pkt_buffer_req_value(w_cpu2ip_write_pkt_buffer_req_value),   
        .cpu2ip_write_pkt_buffer_req_valid(w_cpu2ip_write_pkt_buffer_req_valid[1]),   
        .ip2cpu_write_pkt_buffer_resp_valid(w_ip2cpu_write_pkt_buffer_resp_valid[1]),  
                                                                                                                 
        .cpu2ip_write_sume_buffer_req_addr(w_cpu2ip_write_sume_buffer_req_addr),   
        .cpu2ip_write_sume_buffer_req_value(w_cpu2ip_write_sume_buffer_req_value),  
        .cpu2ip_write_sume_buffer_req_valid(w_cpu2ip_write_sume_buffer_req_valid[1]),  
        .ip2cpu_write_sume_buffer_resp_valid(w_ip2cpu_write_sume_buffer_resp_valid[1]), 
                                                                              
        .cpu2ip_write_pifo_buffer_req_addr(w_cpu2ip_write_pifo_buffer_req_addr),   
        .cpu2ip_write_pifo_buffer_req_value(w_cpu2ip_write_pifo_buffer_req_value),  
        .cpu2ip_write_pifo_buffer_req_valid(w_cpu2ip_write_pifo_buffer_req_valid[1]),  
        .ip2cpu_write_pifo_buffer_resp_valid(w_ip2cpu_write_pifo_buffer_resp_valid[1]), 
                                                                              
        .cpu2ip_write_pifo_calendar_req_addr(w_cpu2ip_write_pifo_calendar_req_addr), 
        .cpu2ip_write_pifo_calendar_req_value(w_cpu2ip_write_pifo_calendar_req_value),
        .cpu2ip_write_pifo_calendar_req_valid(w_cpu2ip_write_pifo_calendar_req_valid[1]),
        .ip2cpu_write_pifo_calendar_resp_valid(w_ip2cpu_write_pifo_calendar_resp_valid[1])
        
    );

    sss_output_queue_single_ip
    sss_output_queue_single_inst_1
    (
    .axis_aclk(axis_aclk),    
    .axis_resetn(axis_resetn),  
                             
    .s_axis_tdata(w_axis_1_tdata_to_sss_output_queue_single), 
    .s_axis_tkeep(w_axis_1_tkeep_to_sss_output_queue_single), 
    .s_axis_tuser(w_axis_1_tuser_to_sss_output_queue_single), 
    .s_axis_tvalid(w_axis_1_tvalid_to_sss_output_queue_single),
    .s_axis_tready(w_axis_1_tready_from_sss_output_queue_single),
    .s_axis_tlast(w_axis_1_tlast_to_sss_output_queue_single), 
                  
                  
    .m_axis_tdata(m_axis_1_tdata), 
    .m_axis_tkeep(m_axis_1_tkeep), 
    .m_axis_tuser(m_axis_1_tuser), 
    .m_axis_tvalid(m_axis_1_tvalid),
    .m_axis_tready(m_axis_1_tready),
    .m_axis_tlast(m_axis_1_tlast)   
    );

    
    wire                        buffer_2_almost_full;
    wire                        pifo_2_full;
    
    wire [BUFFER_INDEX_WIDTH-1:0] buffer_2_queue_depth;
    
    wire [DATA_WIDTH - 1:0]                    w_axis_2_tdata_to_sss_output_queue_single;
    wire [(DATA_WIDTH / 8) - 1:0]              w_axis_2_tkeep_to_sss_output_queue_single;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]            w_axis_2_tuser_to_sss_output_queue_single;
    wire                                       w_axis_2_tvalid_to_sss_output_queue_single;
    wire                                       w_axis_2_tlast_to_sss_output_queue_single;
    wire                                       w_axis_2_tready_from_sss_output_queue_single;
    wire [PIFO_INFO_LENGTH-1:0]                w_axis_2_tpifo_next;
    
    
    pifo_output_queue_ip
    #(
    .BUFFER_ADDR_WIDTH(BUFFER_INDEX_WIDTH),  
    .BUFFER_WORD_DEPTH(BUFFER_WORD_DEPTH),
    .PIFO_WORD_DEPTH(PIFO_CALENDAR_DEPTH),
    .PIFO_ADDR_WIDTH(PIFO_INDEX_WIDTH),  
    .OUTPUT_SYNC(BUFFER_OUTPUT_SYNC)          
    )
    output_queue_inst_port2(
        .s_axis_tdata(s_axis_tdata_d2),
        .s_axis_tkeep(s_axis_tkeep_d2),
        .s_axis_tuser(w_sume_meta_d2),
        .s_axis_tpifo(w_pifo_info_d2),
        .s_axis_tvalid(s_axis_tvalid_d2),
        .s_axis_tlast(s_axis_tlast_d2),
        .s_axis_buffer_wr_en(r_buffer_write_en_bit_array[2]),
        .s_axis_pifo_insert_en(r_pifo_insert_en_bit_array[2]),
        .m_axis_tready(w_axis_2_tready_from_sss_output_queue_single),
        .m_axis_tvalid(w_axis_2_tvalid_to_sss_output_queue_single),
        .m_axis_tdata(w_axis_2_tdata_to_sss_output_queue_single),
        .m_axis_tkeep(w_axis_2_tkeep_to_sss_output_queue_single),
        .m_axis_tlast(w_axis_2_tlast_to_sss_output_queue_single),
        .m_axis_tuser(w_axis_2_tuser_to_sss_output_queue_single),
        .m_axis_tpifo(w_axis_2_tpifo_next),
        .m_is_buffer_almost_full(buffer_2_almost_full),
        .m_is_pifo_full(pifo_2_full),
        .m_buffer_counter(buffer_2_queue_depth),
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn),
        
        .cpu2ip_read_pkt_buffer_req_addr(w_cpu2ip_read_pkt_buffer_req_addr),     
        .cpu2ip_read_pkt_buffer_req_valid(w_cpu2ip_read_pkt_buffer_req_valid[2]),    
//        .ip2cpu_read_pkt_buffer_resp_value(w_ip2cpu_read_pkt_buffer_resp_value),   
        .ip2cpu_read_pkt_buffer_resp_valid(w_ip2cpu_read_pkt_buffer_resp_valid[2]),   
                                                                                 
        .cpu2ip_read_sume_buffer_req_addr(w_cpu2ip_read_sume_buffer_req_addr),    
        .cpu2ip_read_sume_buffer_req_valid(w_cpu2ip_read_sume_buffer_req_valid[2]),   
//        .ip2cpu_read_sume_buffer_resp_value(w_ip2cpu_read_sume_buffer_resp_value),  
        .ip2cpu_read_sume_buffer_resp_valid(w_ip2cpu_read_sume_buffer_resp_valid[2]),  
                                                                         
        .cpu2ip_read_pifo_buffer_req_addr(w_cpu2ip_read_pifo_buffer_req_addr),    
        .cpu2ip_read_pifo_buffer_req_valid(w_cpu2ip_read_pifo_buffer_req_valid[2]),   
//        .ip2cpu_read_pifo_buffer_resp_value(w_ip2cpu_read_pifo_buffer_resp_value),  
        .ip2cpu_read_pifo_buffer_resp_valid(w_ip2cpu_read_pifo_buffer_resp_valid[2]),  
                                
        .cpu2ip_read_pifo_calendar_req_addr(w_cpu2ip_read_pifo_calendar_req_addr),  
        .cpu2ip_read_pifo_calendar_req_valid(w_cpu2ip_read_pifo_calendar_req_valid[2]), 
//        .ip2cpu_read_pifo_calendar_resp_value(w_ip2cpu_read_pifo_calendar_resp_value),
        .ip2cpu_read_pifo_calendar_resp_valid(w_ip2cpu_read_pifo_calendar_resp_valid[2]),
                                                                              
        .cpu2ip_write_pkt_buffer_req_addr(w_cpu2ip_write_pkt_buffer_req_addr),    
        .cpu2ip_write_pkt_buffer_req_value(w_cpu2ip_write_pkt_buffer_req_value),   
        .cpu2ip_write_pkt_buffer_req_valid(w_cpu2ip_write_pkt_buffer_req_valid[2]),   
        .ip2cpu_write_pkt_buffer_resp_valid(w_ip2cpu_write_pkt_buffer_resp_valid[2]),  
                                                                                                                 
        .cpu2ip_write_sume_buffer_req_addr(w_cpu2ip_write_sume_buffer_req_addr),   
        .cpu2ip_write_sume_buffer_req_value(w_cpu2ip_write_sume_buffer_req_value),  
        .cpu2ip_write_sume_buffer_req_valid(w_cpu2ip_write_sume_buffer_req_valid[2]),  
        .ip2cpu_write_sume_buffer_resp_valid(w_ip2cpu_write_sume_buffer_resp_valid[2]), 
                                                                              
        .cpu2ip_write_pifo_buffer_req_addr(w_cpu2ip_write_pifo_buffer_req_addr),   
        .cpu2ip_write_pifo_buffer_req_value(w_cpu2ip_write_pifo_buffer_req_value),  
        .cpu2ip_write_pifo_buffer_req_valid(w_cpu2ip_write_pifo_buffer_req_valid[2]),  
        .ip2cpu_write_pifo_buffer_resp_valid(w_ip2cpu_write_pifo_buffer_resp_valid[2]), 
                                                                              
        .cpu2ip_write_pifo_calendar_req_addr(w_cpu2ip_write_pifo_calendar_req_addr), 
        .cpu2ip_write_pifo_calendar_req_value(w_cpu2ip_write_pifo_calendar_req_value),
        .cpu2ip_write_pifo_calendar_req_valid(w_cpu2ip_write_pifo_calendar_req_valid[2]),
        .ip2cpu_write_pifo_calendar_resp_valid(w_ip2cpu_write_pifo_calendar_resp_valid[2])
        
        
    );

    sss_output_queue_single_ip
    sss_output_queue_single_inst_2
    (
    .axis_aclk(axis_aclk),    
    .axis_resetn(axis_resetn),  
                             
    .s_axis_tdata(w_axis_2_tdata_to_sss_output_queue_single), 
    .s_axis_tkeep(w_axis_2_tkeep_to_sss_output_queue_single), 
    .s_axis_tuser(w_axis_2_tuser_to_sss_output_queue_single), 
    .s_axis_tvalid(w_axis_2_tvalid_to_sss_output_queue_single),
    .s_axis_tready(w_axis_2_tready_from_sss_output_queue_single),
    .s_axis_tlast(w_axis_2_tlast_to_sss_output_queue_single), 
                  
                  
    .m_axis_tdata(m_axis_2_tdata), 
    .m_axis_tkeep(m_axis_2_tkeep), 
    .m_axis_tuser(m_axis_2_tuser), 
    .m_axis_tvalid(m_axis_2_tvalid),
    .m_axis_tready(m_axis_2_tready),
    .m_axis_tlast(m_axis_2_tlast)   
    );
    
    wire                        buffer_3_almost_full;
    wire                        pifo_3_full;
    wire [BUFFER_INDEX_WIDTH-1:0] buffer_3_queue_depth;

    wire [DATA_WIDTH - 1:0]                    w_axis_3_tdata_to_sss_output_queue_single;
    wire [(DATA_WIDTH / 8) - 1:0]              w_axis_3_tkeep_to_sss_output_queue_single;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]            w_axis_3_tuser_to_sss_output_queue_single;
    wire                                       w_axis_3_tvalid_to_sss_output_queue_single;
    wire                                       w_axis_3_tlast_to_sss_output_queue_single;
    wire                                       w_axis_3_tready_from_sss_output_queue_single;
    wire [PIFO_INFO_LENGTH-1:0]                w_axis_3_tpifo_next;

    pifo_output_queue_ip
    #(
    .BUFFER_ADDR_WIDTH(BUFFER_INDEX_WIDTH),  
    .BUFFER_WORD_DEPTH(BUFFER_WORD_DEPTH),
    .PIFO_WORD_DEPTH(PIFO_CALENDAR_DEPTH),
    .PIFO_ADDR_WIDTH(PIFO_INDEX_WIDTH),  
    .OUTPUT_SYNC(BUFFER_OUTPUT_SYNC)          
    )
    output_queue_inst_port3(
        .s_axis_tdata(s_axis_tdata_d2),
        .s_axis_tkeep(s_axis_tkeep_d2),
        .s_axis_tuser(w_sume_meta_d2),
        .s_axis_tpifo(w_pifo_info_d2),
        .s_axis_tvalid(s_axis_tvalid_d2),
        .s_axis_tlast(s_axis_tlast_d2),
        .s_axis_buffer_wr_en(r_buffer_write_en_bit_array[3]),
        .s_axis_pifo_insert_en(r_pifo_insert_en_bit_array[3]),
        .m_axis_tready(w_axis_3_tready_from_sss_output_queue_single),
        .m_axis_tvalid(w_axis_3_tvalid_to_sss_output_queue_single),
        .m_axis_tdata(w_axis_3_tdata_to_sss_output_queue_single),
        .m_axis_tkeep(w_axis_3_tkeep_to_sss_output_queue_single),
        .m_axis_tlast(w_axis_3_tlast_to_sss_output_queue_single),
        .m_axis_tuser(w_axis_3_tuser_to_sss_output_queue_single),
        .m_axis_tpifo(w_axis_3_tpifo_next),
        .m_is_buffer_almost_full(buffer_3_almost_full),
        .m_is_pifo_full(pifo_3_full),
        .m_buffer_counter(buffer_3_queue_depth),
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn),
        
        .cpu2ip_read_pkt_buffer_req_addr(w_cpu2ip_read_pkt_buffer_req_addr),     
        .cpu2ip_read_pkt_buffer_req_valid(w_cpu2ip_read_pkt_buffer_req_valid[3]),    
//        .ip2cpu_read_pkt_buffer_resp_value(w_ip2cpu_read_pkt_buffer_resp_value),   
        .ip2cpu_read_pkt_buffer_resp_valid(w_ip2cpu_read_pkt_buffer_resp_valid[3]),   
                                                                                 
        .cpu2ip_read_sume_buffer_req_addr(w_cpu2ip_read_sume_buffer_req_addr),    
        .cpu2ip_read_sume_buffer_req_valid(w_cpu2ip_read_sume_buffer_req_valid[3]),   
//        .ip2cpu_read_sume_buffer_resp_value(w_ip2cpu_read_sume_buffer_resp_value),  
        .ip2cpu_read_sume_buffer_resp_valid(w_ip2cpu_read_sume_buffer_resp_valid[3]),  
                                                                         
        .cpu2ip_read_pifo_buffer_req_addr(w_cpu2ip_read_pifo_buffer_req_addr),    
        .cpu2ip_read_pifo_buffer_req_valid(w_cpu2ip_read_pifo_buffer_req_valid[3]),   
//        .ip2cpu_read_pifo_buffer_resp_value(w_ip2cpu_read_pifo_buffer_resp_value),  
        .ip2cpu_read_pifo_buffer_resp_valid(w_ip2cpu_read_pifo_buffer_resp_valid[3]),  
                                
        .cpu2ip_read_pifo_calendar_req_addr(w_cpu2ip_read_pifo_calendar_req_addr),  
        .cpu2ip_read_pifo_calendar_req_valid(w_cpu2ip_read_pifo_calendar_req_valid[3]), 
//        .ip2cpu_read_pifo_calendar_resp_value(w_ip2cpu_read_pifo_calendar_resp_value),
        .ip2cpu_read_pifo_calendar_resp_valid(w_ip2cpu_read_pifo_calendar_resp_valid[3]),
                                                                              
        .cpu2ip_write_pkt_buffer_req_addr(w_cpu2ip_write_pkt_buffer_req_addr),    
        .cpu2ip_write_pkt_buffer_req_value(w_cpu2ip_write_pkt_buffer_req_value),   
        .cpu2ip_write_pkt_buffer_req_valid(w_cpu2ip_write_pkt_buffer_req_valid[3]),   
        .ip2cpu_write_pkt_buffer_resp_valid(w_ip2cpu_write_pkt_buffer_resp_valid[3]),  
                                                                                                                 
        .cpu2ip_write_sume_buffer_req_addr(w_cpu2ip_write_sume_buffer_req_addr),   
        .cpu2ip_write_sume_buffer_req_value(w_cpu2ip_write_sume_buffer_req_value),  
        .cpu2ip_write_sume_buffer_req_valid(w_cpu2ip_write_sume_buffer_req_valid[3]),  
        .ip2cpu_write_sume_buffer_resp_valid(w_ip2cpu_write_sume_buffer_resp_valid[3]), 
                                                                              
        .cpu2ip_write_pifo_buffer_req_addr(w_cpu2ip_write_pifo_buffer_req_addr),   
        .cpu2ip_write_pifo_buffer_req_value(w_cpu2ip_write_pifo_buffer_req_value),  
        .cpu2ip_write_pifo_buffer_req_valid(w_cpu2ip_write_pifo_buffer_req_valid[3]),  
        .ip2cpu_write_pifo_buffer_resp_valid(w_ip2cpu_write_pifo_buffer_resp_valid[3]), 
                                                                              
        .cpu2ip_write_pifo_calendar_req_addr(w_cpu2ip_write_pifo_calendar_req_addr), 
        .cpu2ip_write_pifo_calendar_req_value(w_cpu2ip_write_pifo_calendar_req_value),
        .cpu2ip_write_pifo_calendar_req_valid(w_cpu2ip_write_pifo_calendar_req_valid[3]),
        .ip2cpu_write_pifo_calendar_resp_valid(w_ip2cpu_write_pifo_calendar_resp_valid[3])    
        
        
    );

    sss_output_queue_single_ip
    sss_output_queue_single_inst_3
    (
    .axis_aclk(axis_aclk),    
    .axis_resetn(axis_resetn),  
                             
    .s_axis_tdata(w_axis_3_tdata_to_sss_output_queue_single), 
    .s_axis_tkeep(w_axis_3_tkeep_to_sss_output_queue_single), 
    .s_axis_tuser(w_axis_3_tuser_to_sss_output_queue_single), 
    .s_axis_tvalid(w_axis_3_tvalid_to_sss_output_queue_single),
    .s_axis_tready(w_axis_3_tready_from_sss_output_queue_single),
    .s_axis_tlast(w_axis_3_tlast_to_sss_output_queue_single), 
                  
                  
    .m_axis_tdata(m_axis_3_tdata), 
    .m_axis_tkeep(m_axis_3_tkeep), 
    .m_axis_tuser(m_axis_3_tuser), 
    .m_axis_tvalid(m_axis_3_tvalid),
    .m_axis_tready(m_axis_3_tready),
    .m_axis_tlast(m_axis_3_tlast)   
    );
    
    // port 4 is cpu port
    wire                        buffer_4_almost_full;
    wire                        pifo_4_full;
    
    wire [BUFFER_INDEX_WIDTH-1:0] buffer_4_queue_depth;

    wire [DATA_WIDTH - 1:0]                    w_axis_4_tdata_to_sss_output_queue_single;
    wire [(DATA_WIDTH / 8) - 1:0]              w_axis_4_tkeep_to_sss_output_queue_single;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]            w_axis_4_tuser_to_sss_output_queue_single;
    wire                                       w_axis_4_tvalid_to_sss_output_queue_single;
    wire                                       w_axis_4_tlast_to_sss_output_queue_single;
    wire                                       w_axis_4_tready_from_sss_output_queue_single;
    wire [PIFO_INFO_LENGTH-1:0]                w_axis_4_tpifo_next;

    pifo_output_queue_ip
    #(
    .BUFFER_ADDR_WIDTH(BUFFER_INDEX_WIDTH),  
    .BUFFER_WORD_DEPTH(BUFFER_WORD_DEPTH),
    .PIFO_WORD_DEPTH(PIFO_CALENDAR_DEPTH),
    .PIFO_ADDR_WIDTH(PIFO_INDEX_WIDTH),  
    .OUTPUT_SYNC(BUFFER_OUTPUT_SYNC)          
    )
    output_queue_inst_port4(
        .s_axis_tdata(s_axis_tdata_d2),
        .s_axis_tkeep(s_axis_tkeep_d2),
        .s_axis_tuser(w_sume_meta_d2),
        .s_axis_tpifo(w_pifo_info_d2),
        .s_axis_tvalid(s_axis_tvalid_d2),
        .s_axis_tlast(s_axis_tlast_d2),
        .s_axis_buffer_wr_en(r_buffer_write_en_bit_array[4]),
        .s_axis_pifo_insert_en(r_pifo_insert_en_bit_array[4]),
        .m_axis_tready(w_axis_4_tready_from_sss_output_queue_single),
        .m_axis_tvalid(w_axis_4_tvalid_to_sss_output_queue_single),
        .m_axis_tdata(w_axis_4_tdata_to_sss_output_queue_single),
        .m_axis_tkeep(w_axis_4_tkeep_to_sss_output_queue_single),
        .m_axis_tlast(w_axis_4_tlast_to_sss_output_queue_single),
        .m_axis_tuser(w_axis_4_tuser_to_sss_output_queue_single),
        .m_axis_tpifo(w_axis_4_tpifo_next),
        .m_is_buffer_almost_full(buffer_4_almost_full),
        .m_is_pifo_full(pifo_4_full),
        .m_buffer_counter(buffer_4_queue_depth),
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn),
        
        
        .cpu2ip_read_pkt_buffer_req_addr(w_cpu2ip_read_pkt_buffer_req_addr),     
        .cpu2ip_read_pkt_buffer_req_valid(w_cpu2ip_read_pkt_buffer_req_valid[4]),    
//        .ip2cpu_read_pkt_buffer_resp_value(w_ip2cpu_read_pkt_buffer_resp_value),   
        .ip2cpu_read_pkt_buffer_resp_valid(w_ip2cpu_read_pkt_buffer_resp_valid[4]),   
                                                                                 
        .cpu2ip_read_sume_buffer_req_addr(w_cpu2ip_read_sume_buffer_req_addr),    
        .cpu2ip_read_sume_buffer_req_valid(w_cpu2ip_read_sume_buffer_req_valid[4]),   
//        .ip2cpu_read_sume_buffer_resp_value(w_ip2cpu_read_sume_buffer_resp_value),  
        .ip2cpu_read_sume_buffer_resp_valid(w_ip2cpu_read_sume_buffer_resp_valid[4]),  
                                                                         
        .cpu2ip_read_pifo_buffer_req_addr(w_cpu2ip_read_pifo_buffer_req_addr),    
        .cpu2ip_read_pifo_buffer_req_valid(w_cpu2ip_read_pifo_buffer_req_valid[4]),   
//        .ip2cpu_read_pifo_buffer_resp_value(w_ip2cpu_read_pifo_buffer_resp_value),  
        .ip2cpu_read_pifo_buffer_resp_valid(w_ip2cpu_read_pifo_buffer_resp_valid[4]),  
                                
        .cpu2ip_read_pifo_calendar_req_addr(w_cpu2ip_read_pifo_calendar_req_addr),  
        .cpu2ip_read_pifo_calendar_req_valid(w_cpu2ip_read_pifo_calendar_req_valid[4]), 
//        .ip2cpu_read_pifo_calendar_resp_value(w_ip2cpu_read_pifo_calendar_resp_value),
        .ip2cpu_read_pifo_calendar_resp_valid(w_ip2cpu_read_pifo_calendar_resp_valid[4]),
                                                                              
        .cpu2ip_write_pkt_buffer_req_addr(w_cpu2ip_write_pkt_buffer_req_addr),    
        .cpu2ip_write_pkt_buffer_req_value(w_cpu2ip_write_pkt_buffer_req_value),   
        .cpu2ip_write_pkt_buffer_req_valid(w_cpu2ip_write_pkt_buffer_req_valid[4]),   
        .ip2cpu_write_pkt_buffer_resp_valid(w_ip2cpu_write_pkt_buffer_resp_valid[4]),  
                                                                                                                 
        .cpu2ip_write_sume_buffer_req_addr(w_cpu2ip_write_sume_buffer_req_addr),   
        .cpu2ip_write_sume_buffer_req_value(w_cpu2ip_write_sume_buffer_req_value),  
        .cpu2ip_write_sume_buffer_req_valid(w_cpu2ip_write_sume_buffer_req_valid[4]),  
        .ip2cpu_write_sume_buffer_resp_valid(w_ip2cpu_write_sume_buffer_resp_valid[4]), 
                                                                              
        .cpu2ip_write_pifo_buffer_req_addr(w_cpu2ip_write_pifo_buffer_req_addr),   
        .cpu2ip_write_pifo_buffer_req_value(w_cpu2ip_write_pifo_buffer_req_value),  
        .cpu2ip_write_pifo_buffer_req_valid(w_cpu2ip_write_pifo_buffer_req_valid[4]),  
        .ip2cpu_write_pifo_buffer_resp_valid(w_ip2cpu_write_pifo_buffer_resp_valid[4]), 
                                                                              
        .cpu2ip_write_pifo_calendar_req_addr(w_cpu2ip_write_pifo_calendar_req_addr), 
        .cpu2ip_write_pifo_calendar_req_value(w_cpu2ip_write_pifo_calendar_req_value),
        .cpu2ip_write_pifo_calendar_req_valid(w_cpu2ip_write_pifo_calendar_req_valid[4]),
        .ip2cpu_write_pifo_calendar_resp_valid(w_ip2cpu_write_pifo_calendar_resp_valid[4])
           
    );    

    sss_output_queue_single_ip
    sss_output_queue_single_inst_4
    (
    .axis_aclk(axis_aclk),    
    .axis_resetn(axis_resetn),  
                             
    .s_axis_tdata(w_axis_4_tdata_to_sss_output_queue_single), 
    .s_axis_tkeep(w_axis_4_tkeep_to_sss_output_queue_single), 
    .s_axis_tuser(w_axis_4_tuser_to_sss_output_queue_single), 
    .s_axis_tvalid(w_axis_4_tvalid_to_sss_output_queue_single),
    .s_axis_tready(w_axis_4_tready_from_sss_output_queue_single),
    .s_axis_tlast(w_axis_4_tlast_to_sss_output_queue_single), 
                  
                  
    .m_axis_tdata(m_axis_4_tdata), 
    .m_axis_tkeep(m_axis_4_tkeep), 
    .m_axis_tuser(m_axis_4_tuser), 
    .m_axis_tvalid(m_axis_4_tvalid),
    .m_axis_tready(m_axis_4_tready),
    .m_axis_tlast(m_axis_4_tlast)   
    );

    cpu_sub
    #(
    .BUFFER_ADDR_INDEX_WIDTH(BUFFER_INDEX_WIDTH),
    .PIFO_ADDR_INDEX_WIDTH(PIFO_INDEX_WIDTH),  
    .EQ_AGENT_INDEX_WIDTH(CPU_EQ_AGENT_ADDR),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)   
    )
    cpu_sub_inst(
        .S_AXI_ACLK(S_AXI_ACLK),   
        .S_AXI_ARESETN(S_AXI_ARESETN),
                      
        .S_AXI_BREADY(S_AXI_BREADY), 
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWADDR(S_AXI_AWADDR), 
        .S_AXI_WVALID(S_AXI_WVALID), 
        .S_AXI_WDATA(S_AXI_WDATA),  
        .S_AXI_WSTRB(S_AXI_WSTRB),  
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WREADY(S_AXI_WREADY), 
        .S_AXI_BRESP(S_AXI_BRESP),  
        .S_AXI_BVALID(S_AXI_BVALID), 
                      
        .S_AXI_RREADY(S_AXI_RREADY), 
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARADDR(S_AXI_ARADDR), 
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RVALID(S_AXI_RVALID), 
        .S_AXI_RDATA(S_AXI_RDATA),  
        .S_AXI_RRESP(S_AXI_RRESP),  
    
        .cpu2ip_read_pkt_buffer_req_addr(w_cpu2ip_read_pkt_buffer_req_addr),     
        .cpu2ip_read_pkt_buffer_req_valid(w_cpu2ip_read_pkt_buffer_req_valid),    
        .ip2cpu_read_pkt_buffer_resp_value(w_ip2cpu_read_pkt_buffer_resp_value),   
        .ip2cpu_read_pkt_buffer_resp_valid(w_ip2cpu_read_pkt_buffer_resp_valid),   
                                                                                 
        .cpu2ip_read_sume_buffer_req_addr(w_cpu2ip_read_sume_buffer_req_addr),    
        .cpu2ip_read_sume_buffer_req_valid(w_cpu2ip_read_sume_buffer_req_valid),   
        .ip2cpu_read_sume_buffer_resp_value(w_ip2cpu_read_sume_buffer_resp_value),  
        .ip2cpu_read_sume_buffer_resp_valid(w_ip2cpu_read_sume_buffer_resp_valid),  
                                                                         
        .cpu2ip_read_pifo_buffer_req_addr(w_cpu2ip_read_pifo_buffer_req_addr),    
        .cpu2ip_read_pifo_buffer_req_valid(w_cpu2ip_read_pifo_buffer_req_valid),   
        .ip2cpu_read_pifo_buffer_resp_value(w_ip2cpu_read_pifo_buffer_resp_value),  
        .ip2cpu_read_pifo_buffer_resp_valid(w_ip2cpu_read_pifo_buffer_resp_valid),  
                                
        .cpu2ip_read_pifo_calendar_req_addr(w_cpu2ip_read_pifo_calendar_req_addr),  
        .cpu2ip_read_pifo_calendar_req_valid(w_cpu2ip_read_pifo_calendar_req_valid), 
        .ip2cpu_read_pifo_calendar_resp_value(w_ip2cpu_read_pifo_calendar_resp_value),
        .ip2cpu_read_pifo_calendar_resp_valid(w_ip2cpu_read_pifo_calendar_resp_valid),
                                                                              
        .cpu2ip_write_pkt_buffer_req_addr(w_cpu2ip_write_pkt_buffer_req_addr),    
        .cpu2ip_write_pkt_buffer_req_value(w_cpu2ip_write_pkt_buffer_req_value),   
        .cpu2ip_write_pkt_buffer_req_valid(w_cpu2ip_write_pkt_buffer_req_valid),   
        .ip2cpu_write_pkt_buffer_resp_valid(w_ip2cpu_write_pkt_buffer_resp_valid),  
                                                                                                                 
        .cpu2ip_write_sume_buffer_req_addr(w_cpu2ip_write_sume_buffer_req_addr),   
        .cpu2ip_write_sume_buffer_req_value(w_cpu2ip_write_sume_buffer_req_value),  
        .cpu2ip_write_sume_buffer_req_valid(w_cpu2ip_write_sume_buffer_req_valid),  
        .ip2cpu_write_sume_buffer_resp_valid(w_ip2cpu_write_sume_buffer_resp_valid), 
                                                                              
        .cpu2ip_write_pifo_buffer_req_addr(w_cpu2ip_write_pifo_buffer_req_addr),   
        .cpu2ip_write_pifo_buffer_req_value(w_cpu2ip_write_pifo_buffer_req_value),  
        .cpu2ip_write_pifo_buffer_req_valid(w_cpu2ip_write_pifo_buffer_req_valid),  
        .ip2cpu_write_pifo_buffer_resp_valid(w_ip2cpu_write_pifo_buffer_resp_valid), 
                                                                              
        .cpu2ip_write_pifo_calendar_req_addr(w_cpu2ip_write_pifo_calendar_req_addr), 
        .cpu2ip_write_pifo_calendar_req_value(w_cpu2ip_write_pifo_calendar_req_value),
        .cpu2ip_write_pifo_calendar_req_valid(w_cpu2ip_write_pifo_calendar_req_valid),
        .ip2cpu_write_pifo_calendar_resp_valid(w_ip2cpu_write_pifo_calendar_resp_valid),
        
        .cpu2ip_read_stat_enqueue_agent_req_addr(w_cpu2ip_read_stat_enqueue_agent_req_addr),
        .cpu2ip_read_stat_enqueue_agent_req_valid(w_cpu2ip_read_stat_enqueue_agent_req_valid),
        .ip2cpu_read_stat_enqueue_agent_resp_value(w_ip2cpu_read_stat_enqueue_agent_resp_value),
        .ip2cpu_read_stat_enqueue_agent_resp_valid(w_ip2cpu_read_stat_enqueue_agent_resp_valid)
    );


always @(posedge axis_aclk)
begin
    if(~axis_resetn)
        begin
            s_axis_tdata_d1  <= 0; 
            s_axis_tkeep_d1  <= 0; 
            s_axis_tuser_d1  <= 0; 
            s_axis_tvalid_d1 <= 0;
            s_axis_tlast_d1  <= 0; 

            s_axis_tdata_d2  <= 0; 
            s_axis_tkeep_d2  <= 0; 
            s_axis_tuser_d2  <= 0; 
            s_axis_tvalid_d2 <= 0;
            s_axis_tlast_d2  <= 0; 
            
            
            r_m_axis_0_tpifo <= 0;
            r_m_axis_1_tpifo <= 0;
            r_m_axis_2_tpifo <= 0;
            r_m_axis_3_tpifo <= 0;
            r_m_axis_4_tpifo <= 0;
            
            r_buffer_write_en_bit_array <= 0;
            r_pifo_insert_en_bit_array <=0 ; 

            
        end
    else
        begin
            s_axis_tdata_d1  <= s_axis_tdata; 
            s_axis_tkeep_d1  <= s_axis_tkeep; 
            s_axis_tuser_d1  <= s_axis_tuser; 
            s_axis_tvalid_d1 <= s_axis_tvalid;
            s_axis_tlast_d1  <= s_axis_tlast; 

            s_axis_tdata_d2  <= s_axis_tdata_d1; 
            s_axis_tkeep_d2  <= s_axis_tkeep_d1; 
            s_axis_tuser_d2 <= s_axis_tuser_d1; 
            s_axis_tvalid_d2 <= s_axis_tvalid_d1;
            s_axis_tlast_d2  <= s_axis_tlast_d1; 

            r_m_axis_0_tpifo <= w_axis_0_tpifo_next;
            r_m_axis_1_tpifo <= w_axis_1_tpifo_next;
            r_m_axis_2_tpifo <= w_axis_2_tpifo_next;
            r_m_axis_3_tpifo <= w_axis_3_tpifo_next;
            r_m_axis_4_tpifo <= w_axis_4_tpifo_next;

            r_buffer_write_en_bit_array <= w_buffer_write_en_bit_array;
            r_pifo_insert_en_bit_array <= w_pifo_insert_en_bit_array; 

        end
end

assign  w_pifo_info_d2 = s_axis_tuser_d2[C_S_AXIS_TUSER_WIDTH-1:C_S_AXIS_TUSER_WIDTH-PIFO_INFO_LENGTH];    
assign  w_sume_meta_d2 = s_axis_tuser_d2[C_S_AXIS_TUSER_WIDTH-PIFO_INFO_LENGTH-1:0];
assign w_buffer_almost_full_bit_array = {buffer_4_almost_full,buffer_3_almost_full,buffer_2_almost_full,buffer_1_almost_full,buffer_0_almost_full};
assign w_pifo_full_bit_array = {pifo_4_full,pifo_3_full,pifo_2_full,pifo_1_full,pifo_0_full};
assign nf0_q_size = {4'b0, buffer_0_queue_depth};
assign nf1_q_size = {4'b0, buffer_1_queue_depth};
assign nf2_q_size = {4'b0, buffer_2_queue_depth};
assign nf3_q_size = {4'b0, buffer_3_queue_depth};
assign dma_q_size = {4'b0, buffer_4_queue_depth}; 

assign m_axis_0_tpifo = r_m_axis_0_tpifo;
assign m_axis_1_tpifo = r_m_axis_1_tpifo;
assign m_axis_2_tpifo = r_m_axis_2_tpifo;
assign m_axis_3_tpifo = r_m_axis_3_tpifo;
assign m_axis_4_tpifo = r_m_axis_4_tpifo;

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2019 01:53:02 PM
// Design Name: 
// Module Name: buffer_wrapper_v0_1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// buffer_wrapper_v1 is a wrapper module for block ram modules which is generated by IP Catalog.
// 3 brams:
// 1. pkt buffer: use bram 289 * 4096
// 2. meta buffer:use bram 128 * 4096
// 3. pifo buffer: use bram 32 * 4096
// 
// In current version, use output_registerd flag for return 
// synce or async data

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module buffer_wrapper_v0_1
    #(
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter C_M_AXIS_PIFO_WIDTH=32,
    parameter C_S_AXIS_PIFO_WIDTH=32,
    parameter C_S_AXIS_ADDR_WIDTH=12
    
    )
    (
    
    s_axis_tdata,
    s_axis_tkeep,
    s_axis_tlast,
    s_axis_tuser,
    s_axis_tpifo,
    
    m_axis_tdata,
    m_axis_tkeep,
    m_axis_tlast,
    m_axis_tuser,
    m_axis_tpifo,
//    m_axis_tvalid,
    
    s_axis_wr_addr,
    s_axis_wr_en,
    s_axis_rd_addr,
//    s_axis_rd_en,
    
    //m_axis_valid,
    
    s_axis_sync_flag,
    clk,
    rstn
    );


    input [C_S_AXIS_DATA_WIDTH-1:0]   s_axis_tdata;
    input [C_S_AXIS_DATA_WIDTH/8-1:0] s_axis_tkeep;
    input                             s_axis_tlast;
    input [C_S_AXIS_TUSER_WIDTH-1:0]  s_axis_tuser;
    input [C_S_AXIS_PIFO_WIDTH-1:0]   s_axis_tpifo;
    
    input [C_S_AXIS_ADDR_WIDTH-1:0]   s_axis_wr_addr;
    input [C_S_AXIS_ADDR_WIDTH-1:0]   s_axis_rd_addr;
    input s_axis_wr_en;
//    input s_axis_rd_en;
    
    input s_axis_sync_flag; // it this field is 1 then return sync value, else return async value.
    
//    output                              m_axis_tvalid;
    output [C_M_AXIS_DATA_WIDTH-1:0]    m_axis_tdata;
    output [C_M_AXIS_DATA_WIDTH/8-1:0]  m_axis_tkeep;
    output                              m_axis_tlast;
    output [C_M_AXIS_TUSER_WIDTH-1:0]   m_axis_tuser;
    output [C_M_AXIS_PIFO_WIDTH-1:0 ]   m_axis_tpifo;
    
    // TODO: 
    // how to return valid value??
    // 
    //output                              m_axis_valid; 
    
    input clk;
    input rstn;
    
    // wires    
    wire [C_M_AXIS_DATA_WIDTH-1:0]      m_axis_tdata_async;
    wire [C_M_AXIS_DATA_WIDTH/8-1:0]    m_axis_tkeep_async;
    wire                                m_axis_tlast_async;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]     m_axis_tuser_async;
    wire [C_M_AXIS_PIFO_WIDTH-1:0 ]     m_axis_tpifo_async;
    wire                                m_axis_tvalid_async;
    
    // regs
    reg [C_M_AXIS_DATA_WIDTH-1:0]       m_axis_tdata_reg;
    reg [C_M_AXIS_DATA_WIDTH/8-1:0]     m_axis_tkeep_reg;
    reg                                 m_axis_tlast_reg;
    reg [C_M_AXIS_TUSER_WIDTH-1:0]      m_axis_tuser_reg;
    reg [C_M_AXIS_PIFO_WIDTH-1:0 ]      m_axis_tpifo_reg;
    reg                                 m_axis_tvalid_reg;
        
    
    buffer_pkt_289_4096
    buffer_pkt_inst(
    .dina({s_axis_tlast,s_axis_tkeep,s_axis_tdata}),
    .wea(s_axis_wr_en),
    .addra(s_axis_wr_addr),  // always write to the fl_head
    
    
    .addrb(s_axis_rd_addr),
    .doutb({m_axis_tlast_async,m_axis_tkeep_async,m_axis_tdata_async}),
    .clka(clk),
    .clkb(clk)
    );

    buffer_meta_128_4096
    buffer_meta_inst(
    .dina(s_axis_tuser),
    .wea(s_axis_wr_en),
    .addra(s_axis_wr_addr),  // always write to the fl_head
    .addrb(s_axis_rd_addr),
    .doutb(m_axis_tuser_async),
    .clka(clk),
    .clkb(clk)
    );
    
    buffer_pifo_32_4096
    buffer_pifo_inst(
    .dina(s_axis_tpifo),
    .wea(s_axis_wr_en),
    .addra(s_axis_wr_addr),  // always write to the fl_head
    .addrb(s_axis_rd_addr),
    .doutb(m_axis_tpifo_async),
    .clka(clk),
    .clkb(clk)
    );

    always @(posedge clk) begin
    
        if(~rstn)
            begin
                m_axis_tdata_reg <= 0;
                m_axis_tkeep_reg <= 0;
                m_axis_tlast_reg <= 0;
                m_axis_tuser_reg <= 0;
                m_axis_tpifo_reg <= 0;
                m_axis_tvalid_reg <= 0;                                                        
            end
        else
            begin
                m_axis_tdata_reg <= m_axis_tdata_async;
                m_axis_tkeep_reg <= m_axis_tkeep_async;
                m_axis_tlast_reg <= m_axis_tlast_async;
                m_axis_tuser_reg <= m_axis_tuser_async;
                m_axis_tpifo_reg <= m_axis_tpifo_async;
                m_axis_tvalid_reg <= m_axis_tvalid_async;  
            end
    end

//// just return input value.
//assign m_axis_tvalid_async = s_axis_rd_en; 

assign m_axis_tdata = (s_axis_sync_flag)? m_axis_tdata_async : m_axis_tdata_reg;
assign m_axis_tkeep = (s_axis_sync_flag)? m_axis_tkeep_async : m_axis_tkeep_reg;
assign m_axis_tlast = (s_axis_sync_flag)? m_axis_tlast_async : m_axis_tlast_reg;
assign m_axis_tuser = (s_axis_sync_flag)? m_axis_tuser_async : m_axis_tuser_reg;
assign m_axis_tpifo = (s_axis_sync_flag)? m_axis_tpifo_async : m_axis_tpifo_reg;
//assign m_axis_tvalid = (s_axis_sync_flag)? m_axis_tvalid_async : m_axis_tvalid_reg;

endmodule

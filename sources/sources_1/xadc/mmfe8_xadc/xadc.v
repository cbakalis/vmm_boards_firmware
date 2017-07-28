`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Reid Pinkham
//
// Copyright Notice/Copying Permission:
//    Copyright 2017 Reid Pinkham
//
//    This file is part of NTUA-BNL_VMM_firmware.
//
//    NTUA-BNL_VMM_firmware is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    NTUA-BNL_VMM_firmware is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with NTUA-BNL_VMM_firmware.  If not, see <http://www.gnu.org/licenses/>.
// 
// Create Date: 15.06.2016 19:18:34
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module xadcModule #
(
    parameter   max_packet_size	= 9'b10010110 // Max of 150 packets per UDP frame
//    parameter   sample_size	= 11'b1111111111, // 1023 packets
//    parameter   delay_in = 18'b11111111111111111 // Delay 131072 clock cycles to spread 1023 samples over ~0.7 seconds
)
(
    input           clk125,
    input           rst,
    
    input           VP_0,
    input           VN_0,
    input           Vaux0_v_n,
    input           Vaux0_v_p,
    input           Vaux1_v_n,
    input           Vaux1_v_p,
    input           Vaux2_v_n,
    input           Vaux2_v_p,
    input           Vaux3_v_n,
    input           Vaux3_v_p,
    input           Vaux8_v_n,
    input           Vaux8_v_p,
    input           Vaux9_v_n,
    input           Vaux9_v_p,
    input           Vaux10_v_n,
    input           Vaux10_v_p,
    input           Vaux11_v_n,
    input           Vaux11_v_p,
    input           data_in_rdy,
    input [15:0]    vmm_id,
    input [10:0]    sample_size,
    input [17:0]    delay_in,
    input           UDPDone,

    output          MuxAddr0,
    output          MuxAddr1,
    output          MuxAddr2,
    output          MuxAddr3_p,
    output          MuxAddr3_n,
    output          end_of_data,
    output [63:0]   fifo_bus,
    output          data_fifo_enable,
    output [11:0]   packet_len,
    output          xadc_busy
);


wire            rst_pkt;
wire            rst_pkt2;
wire [6:0]      daddr;
wire            den;
wire [15:0]     di;
wire            dwe;
wire            rst_xadc;
wire            busy_xadc;
wire [4:0]      channel;
wire [15:0]     do_out;
wire            drdy;
wire            eoc;
wire            eos;
wire            convst;
wire            start;
wire [3:0]      mux_select;
wire [4:0]      ch_sel;
wire [4:0]      ch_request;
wire            xadc_done;
wire [11:0]     result;
wire [3:0]      mux_request;
wire            configuring;
wire            conf_done;
wire            init_chan;
wire            chan_done;
wire            init_type;
wire            save;
wire            fifo_done;
wire            full_pkt;

reg [3:0]       st;
reg             rst_pkt_r;
reg             rst_pkt2_r;
reg [3:0]       st_chan;
reg [3:0]       st_type;
reg [3:0]       st_pkt;
reg             write_start;
reg [3:0]       st_wr;
reg [63:0]      fifo_bus_r;
reg             data_fifo_enable_r;
reg [2:0]       cnt_fifo;
reg [4:0]       cnt_delay;
reg [11:0]       packet_len_r;
reg             xadc_start_r;
reg [4:0]       ch_sel_r;
reg [10:0]      cnt;
reg [17:0]      delay; 
reg             configuring_r;
reg [11:0]      xadc_result_r;
reg             save_r;
reg             chan_done_r;
reg             init_chan_r;
reg             type_done_r;
reg [63:0]      packet; // Putting 5 12-bit words in each packet
reg [8:0]       pkt_cnt;
reg [2:0]       read_cnt;
reg [15:0]      vmm_id_r;
reg [2:0]       vmm_id_sel;
reg [2:0]       cmd_cnt;
reg             init_type_r;
reg             fifo_done_r;
reg             end_of_data_r;
reg             full_pkt_r;
reg [11:0]      test_counter = 0; // Initialize to zero to ensure accurate counts
reg             xadc_busy_r;

parameter idle = 4'b0, st1 = 4'b1, st2 = 4'b10, st3 = 4'b11, st4 = 4'b100, st5 = 4'b101, st6 = 4'b110, st7 = 4'b111;
parameter st8 = 4'b1000, st9 = 4'b1001, st10 = 4'b1010, st11 = 4'b1011, st12 = 4'b1100, st13 = 4'b1101;
parameter st14 = 4'b1110, st15 = 4'b1111;


assign MuxAddr0 = mux_select[0];
assign MuxAddr1 = mux_select[1];
assign MuxAddr2 = mux_select[2];
assign MuxAddr3_p = mux_select[3];
assign MuxAddr3_n = -1 * mux_select[3];

assign data_fifo_enable = data_fifo_enable_r;
assign fifo_bus = fifo_bus_r;
assign packet_len = packet_len_r;
assign xadc_start = xadc_start_r;
assign ch_sel = ch_sel_r;
assign configuring = configuring_r;
assign init_chan = init_chan_r;
assign chan_done = chan_done_r;
assign type_done = type_done_r;
assign save = save_r;
assign init_type = init_type_r;
assign fifo_done = fifo_done_r;
assign rst_pkt = rst_pkt_r;
assign rst_pkt2 = rst_pkt2_r;
assign end_of_data = end_of_data_r;
assign full_pkt = full_pkt_r;
assign xadc_busy = xadc_busy_r;


always @(posedge clk125)
begin
    if (rst == 1'b1)
        begin
            test_counter <= 12'b0;
        end
    else if (data_fifo_enable == 1'b1)
        test_counter <= test_counter + 1'b1;
end



// Main state machine to drive the xADC measurements
always @(posedge clk125)
begin
    if (rst == 1'b1)
        begin
            st <= idle;
            cmd_cnt <= 3'b0;
            cnt <= 11'b0;
            delay <= 18'b0;
            vmm_id_sel <= 3'b0;
            xadc_busy_r <= 1'b0;
        end
    else
        begin
        case(st)
            idle :
                begin
                    if (data_in_rdy == 1'b1)
                        begin
                            xadc_busy_r <= 1'b1;
                            if (vmm_id_r[3:0] > 4'b111) // Read all VMMs
                                vmm_id_sel <= 3'b0; // Incremented in last state
                            else
                                vmm_id_sel <= vmm_id_r[2:0];
                            st <= st1;
                        end
                    else
                        st <= idle;
                end

            st1 : // Begin the xadc read
                begin
                    st <= st2;
                    init_type_r <= 1'b1;
                    cnt <= cnt + 1'b1;
                    delay <= 18'b0;
                end

            st2 : // State to wait for packet to be read and saved
                begin
                    init_type_r <= 1'b0;
                    if (type_done == 1'b1)
                        begin
                            if (cnt == sample_size)
                                begin
                                    st <= st4;
                                    write_start <= 1'b1;
                                end
                            else // Repeat for other reads
                                st <= st3;
                        end
                    else
                        st <= st2;
                end

            st3 : // Delay between packets
                begin
                    delay <= delay + 1'b1;
                    if (delay == delay_in)
                        begin
                            delay <= 18'b0;
                            st <= st1; // Read new value
                        end
                    else
                        st <= st3;
                end

            st4 : // Wait for send to finish, then send done and go to idle
                begin
                    if (fifo_done == 1'b1) // Done reading
                        begin
                            write_start <= 1'b0;
                            cnt <= 11'b0;
                            if (vmm_id_r[3:0] > 4'b111 && vmm_id_sel != 3'b111) // Read all VMMs + stop condition
                                begin
                                    vmm_id_sel <= vmm_id_sel + 1'b1; // Increment
                                    st <= st1;
                                end
                            else    
                                st <= st5; // wait for old command to expire
                        end
                    else
                        st <= st4;
                end

            st5 : // Wait for old command to expire and UDP to be sent
                begin
                    if (data_in_rdy == 1'b0 & UDPDone == 1'b1)
                        begin
                            xadc_busy_r <= 1'b0;
                            st <= idle;
                        end
                    else
                        st <= st5;
                end

            default : st <= idle;
        endcase
        end
end



// Process to latch data when ready
always @(posedge clk125)
begin
    if (data_in_rdy == 1'b1)
        vmm_id_r <= vmm_id - 1'b1;
        
end


// State machine to handle the Type distinguisher
always @(posedge clk125)
begin
    if (rst)
        begin
            st_type <= idle;
            type_done_r <= 1'b0;
            init_chan_r <= 1'b0;
        end
    else
        begin
        case(st_type)
            idle : // wait for start signal
                begin
                    type_done_r <= 1'b0;
                    if (init_type == 1'b1)
                        st_type <= st1;
                    else
                        st_type <= idle;
                end

            st1 : // Read 1 VMM
                begin
                    init_chan_r <= 1'b1;
                    st_type <= st2;
                end

            st2 : // Wait for conversion to complete, then give done signal
                begin
                    init_chan_r <= 1'b0;
                    if (chan_done == 1'b1)
                        begin
                            type_done_r <= 1'b1;
                            st_type <= idle;
                        end
                    else
                        st_type <= st2;
                end

            default : st_type <= idle;

        endcase
        end
end


// State machine to handle the channel selection
always @(posedge clk125)
begin
    if (rst)
        begin
            st_chan <= idle;
            xadc_start_r <= 1'b0;
            save_r <= 1'b0;
            xadc_result_r <= 12'b0;
        end
    else
        begin
        case(st_chan)
            idle :
                begin
                    chan_done_r <= 1'b0;
                    if (init_chan == 1'b1)
                        st_chan <= st1;
                    else
                        st_chan <= idle;
                end

            st1 : // Select the appropriate PDO
                begin
                    ch_sel_r <= {2'b00, vmm_id_sel}; // read the PDO
                    st_chan <= st2;
                end

            st2 : // Begin the conversion
                begin
                    xadc_start_r <= 1'b1;
                    st_chan <= st3;
                end

            st3 : // Wait for done signal, then save data
                begin
                    xadc_start_r <= 1'b0;
                    if (xadc_done == 1'b1)
                        begin
                            xadc_result_r <= result;
                            save_r <= 1'b1; // Indicate to add the result to the packet
                            st_chan <= st4;
                        end
                end

            st4 : // Drive save to zero, indicate done
                begin
                    save_r <= 1'b0;
                    chan_done_r <= 1'b1;
                    st_chan <= idle;
                end

            default : st_chan <= idle;
        endcase
        end
end


// State machine to fill packets with data
always @(posedge clk125)
begin
    if(rst)
        begin
            st_pkt <= idle;
            read_cnt <= 3'b0;
            packet <= 64'b0;
            full_pkt_r <= 1'b0;
            pkt_cnt <= 9'b0;
        end
    if(rst_pkt)
        begin
            st_pkt <= idle;
            read_cnt <= 3'b0;
            packet <= 64'b0;
            full_pkt_r <= 1'b0;
        end
    else if (rst_pkt2 == 1'b1)
        pkt_cnt <= 9'b0;
    else
        begin
        case(st_pkt)
            idle :
                begin
                    if (save == 1'b1)// packet is ready on the input line
                        begin
                            st_pkt <= st1;
                        end
                    else
                        st_pkt <= idle;
                end

            st1 : // Save packet acoording to what has already been saved
                begin
                    packet[63:60] <= {1'b0, vmm_id_sel}; // Header of the vmm_id
                    if (read_cnt == 3'b000) packet[11:0] <= xadc_result_r;
                    else if (read_cnt == 3'b001) packet[23:12] <= xadc_result_r;
                    else if (read_cnt == 3'b010) packet[35:24] <= xadc_result_r;
                    else if (read_cnt == 3'b011) packet[47:36] <= xadc_result_r;
                    else if (read_cnt == 3'b100) packet[59:48] <= xadc_result_r;

                    if (read_cnt == 3'b100) // packet is full, send packet and reset the read_cnt
                        begin
                            read_cnt <= 3'b0;
                            full_pkt_r <= 1'b1;
                        end
                    else if (read_cnt == 3'b000) // Packet has data, increment packet count on first write
                        begin
                            pkt_cnt <= pkt_cnt + 1'b1; // Increment the packet count
                            read_cnt <= read_cnt + 1'b1;
                        end
                    else
                        read_cnt <= read_cnt + 1'b1;

                    st_pkt <= st2;
                end

            st2 : // Wait for signal to go low, ensure no double saving
                begin
                    full_pkt_r <= 1'b0;
                    if (save == 1'b0) // save opperation is complete
                        st_pkt <= idle;
                    else
                        st_pkt <= st2;
                end

            default : st_pkt <= idle;
        endcase
        end
end


// State machine to write to the data fifo
always @(posedge clk125)
begin
    if (rst)
        begin
            st_wr <= idle;
            cnt_fifo <= 3'b0;
            rst_pkt_r <= 1'b1; // Ties rst_pkt to global reset
        end
    else
        begin
        case (st_wr)
            idle :
                begin
                    data_fifo_enable_r <= 1'b0; // Hold it low
                    rst_pkt_r <= 1'b0;
                    if (full_pkt == 1'b1 || write_start == 1'b1) // send one packet
                        begin
                            st_wr <= st1;
                            packet_len_r <= {3'b0, pkt_cnt};
                        end
                    else
                        st_wr <= idle;
                end

            st1 : // loop state for writing
                begin
                    data_fifo_enable_r <= 1'b1;
                    st_wr <= st2;
                    fifo_bus_r <= packet;

                    if (pkt_cnt == max_packet_size || write_start == 1'b1) // If maximum packets or finished with data
                        begin
                            end_of_data_r <= 1'b1;
                            fifo_done_r <= 1'b1;
                            rst_pkt2_r <= 1'b1; // reset the packet count
                        end
                end

        st2 : // Reset packet contents
            begin
                rst_pkt2_r <= 1'b0;
                fifo_done_r <= 1'b0;
                data_fifo_enable_r <= 1'b0;
                rst_pkt_r <= 1'b1;
                end_of_data_r <= end_of_data_r; // Ensure the 125 MHz clock can recieve the signal
                st_wr <= st3;
            end

        st3 : // Wait state
            begin
                st_wr <= idle;
                end_of_data_r <= 1'b0;
            end

        default :
            st_wr <= idle;
        endcase
        end
end



//ila_1 ila_1
//(
//    .clk(clk125),
//    .probe0(data_fifo_enable), // 1
//    .probe1(fifo_bus), // 64
//    .probe2(packet_len), // 12
//    .probe3(xadc_start), //1
//    .probe4(ch_sel), // 5
//    .probe5(configuring), // 1
//    .probe6(init_chan), // 1
//    .probe7(chan_done), // 1
//    .probe8(type_done), // 1
//    .probe9(save), // 1
//    .probe10(init_type), // 1
//    .probe11(fifo_done), // 1
//    .probe12(rst_pkt), // 1
//    .probe13(end_of_data), // 1
//    .probe14(vmm_id), // 16
//    .probe15(st_wr), // 4
//    .probe16(st_pkt), // 4
//    .probe17(st_chan), // 4
//    .probe18(st), // 4
//    .probe19(data_in_rdy), // 1
//    .probe20(pkt_cnt), // 9
//    .probe21(cnt), // 11
//    .probe22(test_counter), // 12
//    .probe23(vmm_id_sel) // 3
//);


xadc_wiz_0 xadc
(
    .convst_in(convst),
    .daddr_in(daddr),
    .dclk_in(clk125),
    .den_in(den),
    .di_in(di),
    .dwe_in(dwe),
    .reset_in(rst_xadc),
    .vp_in(VP_0),
    .vn_in(VN_0),
    .vauxp0(Vaux0_v_p),
    .vauxn0(Vaux0_v_n),
    .vauxp1(Vaux1_v_p),
    .vauxn1(Vaux1_v_n),
    .vauxp2(Vaux2_v_p),
    .vauxn2(Vaux2_v_n),
    .vauxp3(Vaux3_v_p),
    .vauxn3(Vaux3_v_n),
    .vauxp8(Vaux8_v_p),
    .vauxn8(Vaux8_v_n),
    .vauxp9(Vaux9_v_p),
    .vauxn9(Vaux9_v_n),
    .vauxp10(Vaux10_v_p),
    .vauxn10(Vaux10_v_n),
    .vauxp11(Vaux11_v_p),
    .vauxn11(Vaux11_v_n),

    .busy_out(busy_xadc),
    .channel_out(channel),
    .do_out(do_out),
    .drdy_out(drdy),
    .eoc_out(eoc),
    .eos_out(eos),
    .alarm_out()
);


xadc_read XADC
(
    .clk125(clk125),
    .rst(rst),
    .start(xadc_start),
    .ch_sel(ch_sel),
    .busy_xadc(busy_xadc),
    .drdy(drdy),
    .channel(channel),
    .do_out(do_out),
    .eoc(eoc),
    .eos(eos),

    .done(xadc_done),
    .result(result),
    .convst(convst),
    .daddr(daddr),
    .den(den),
    .dwe(dwe),
    .di(di),
    .rst_xadc(rst_xadc),
    .mux_select(mux_select)
);

endmodule

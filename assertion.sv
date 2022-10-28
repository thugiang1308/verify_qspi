
module assertion (intf intf);
  logic [7:0] cmd_m_send;
  // logic [DWIDTH_ADDRESS-1:0] addr_m_send;
  logic [23:0] addr_m_send;

	bit dis_err_ckeck =0;
	// seq1
	sequence seq1;
		intf.o_done ## 2 intf.SS;
	endsequence

	property seq1_check;
		@(posedge  intf.i_clk) disable iff(~intf.i_rst_n) intf.o_done |-> seq1;
	endproperty

	assert property (seq1_check) $display("%t seq1 check PASS",$time);
	else $display("%t seq1 check FAIL",$time);
 
	// seq2
	assert property 

		(@(posedge  intf.i_clk) disable iff (!intf.i_rst_n || dis_err_ckeck) ((intf.i_command == 8'h0b || intf.i_command== 8'hbb) ) |-> $isunknown(intf.SO3 && intf.SO2))
	else begin
		dis_err_ckeck =1;
		$display("%t seq2 check FAIL",$time);
	end

	property P_PERIOD_CLK;
		realtime time_posedge_old;
		@(posedge  intf.SCLK) disable iff(~intf.i_rst_n || intf.SS) (1,time_posedge_old = $realtime()) |=> ($realtime() - time_posedge_old) == 120ns;
	endproperty
	AP_PERIOD_CLK: assert property (P_PERIOD_CLK);
	CP_PERIOD_CLK: cover property (P_PERIOD_CLK); 

	//detect values refer
	initial begin
		fork
			forever begin
				@(negedge intf.SS);
        cmd_m_send  = intf.i_command;
        addr_m_send = intf.i_addr;
			end
		join_none
	end

  property P_CMD;
    int cnt ;
    bit [7:0] cmd_reg;
    @(posedge  intf.i_clk) ($fell(intf.SS), cnt = 0, cmd_reg = 0) 
    ##0 @(posedge intf.SCLK) (cnt <7, cmd_reg = cmd_reg << 1, cmd_reg[0] = intf.SO0,$display("@%10t cnt: %d cmd_reg:%b",$time(),cnt, cmd_reg) ,cnt++) [*0:$] 
    ##1 @(posedge intf.SCLK) (cnt == 7,cmd_reg = cmd_reg << 1, cmd_reg[0] = intf.SO0, $display("@%10t___ cnt: %d cmd_reg:%h",$time,cnt, cmd_reg) ) 
    |-> (cmd_m_send == cmd_reg, $display("GIONG NHAU"));
  endproperty
  AP_CMD: assert property (P_CMD);
  CP_CMD: cover property  (P_CMD);

  sequence P_CMD_SEQ;
    int cnt ;
    bit [7:0] cmd_reg;
    @(posedge  intf.i_clk) ($fell(intf.SS), cnt = 0, cmd_reg = 0) 
    ##0 @(posedge intf.SCLK) (cnt <7, cmd_reg = cmd_reg << 1, cmd_reg[0] = intf.SO0,cnt++,$display("@%10t cnt: %d cmd_reg:%b",$realtime,cnt, cmd_reg) ) [*0:$] 
    ##1 @(posedge intf.SCLK) (cnt == 7,cmd_reg = cmd_reg << 1, cmd_reg[0] = intf.SO0, $display("@%10t___ cnt: %d cmd_reg:%h",$realtime,cnt, cmd_reg) ) 
    ##0 (cmd_m_send == cmd_reg , $display("GIONG NHAU"));
  endsequence

  property P_ADDR_0b (int add_cycle);
    int cnt =0 ;
    bit [31:0] addr_reg = 0;
    @(posedge intf.SCLK) disable iff(cmd_m_send != 'h0b ) P_CMD_SEQ 
    |=> (cnt < add_cycle, addr_reg = addr_reg << 1,$display("%t SO0 %b",$realtime, intf.SO0), addr_reg[0] = intf.SO0, cnt = cnt +1) [*0:$] 
    ##0 (1,$display("@%10t cnt: %d addr_reg:%b",$realtime,cnt, addr_reg)) 
    ##1 (cnt == add_cycle) 
    ##0 (1,$display("@%10t___ cnt: %d addr_reg:%h, addr_reg:%b",$realtime,cnt, addr_reg,addr_reg) ) 
    |-> (addr_m_send == addr_reg);
  endproperty
  AP_ADDR_0b: assert property (P_ADDR_0b(24));
  CP_ADDR_0b: cover property  (P_ADDR_0b(24));

 property P_ADDR_bb (int add_cycle);
    int cnt = 0 ;
    bit [31:0] addr_reg = 0;
    @(posedge intf.SCLK) disable iff(cmd_m_send != 'hbb) P_CMD_SEQ 
    |=> (cnt < add_cycle, addr_reg = addr_reg << 1,$display("%t SO1 %b",$realtime, intf.SO1), addr_reg[0] = intf.SO1, addr_reg = addr_reg << 1,$display("%t SO0 %b", $realtime,intf.SO0), addr_reg[0] = intf.SO0, cnt = cnt +1) [*0:$] 
    ##0 (1,$display("@%10t cnt: %d addr_reg:%b",$realtime,cnt, addr_reg)) 
    ##1 (cnt == add_cycle) 
    ##0 (1,$display("@%10t___ cnt: %d addr_reg:%h, addr_reg:%b",$realtime,cnt, addr_reg,addr_reg) ) 
    |-> (addr_m_send == addr_reg);
  endproperty
  AP_ADDR_bb: assert property (P_ADDR_bb(12));
  CP_ADDR_bb: cover property  (P_ADDR_bb(12));
 property P_ADDR_eb (int add_cycle);
    int cnt =0 ;
    bit [31:0] addr_reg = 0;
    @(posedge intf.SCLK) disable iff(cmd_m_send != 'heb) P_CMD_SEQ 
    |=> (cnt < add_cycle, addr_reg = addr_reg << 1,$display("%t SO3 %b",$realtime, intf.SO3), addr_reg[0] = intf.SO3, addr_reg = addr_reg << 1,$display("%t SO2 %b",$realtime, intf.SO2), addr_reg[0] = intf.SO2,addr_reg = addr_reg << 1,$display("%t SO1 %b",$realtime, intf.SO1), addr_reg[0] = intf.SO1,addr_reg = addr_reg << 1,$display("%t SO0 %b",$realtime, intf.SO0), addr_reg[0] = intf.SO0, cnt = cnt +1) [*0:$] 
    ##0 (1,$display("@%10t cnt: %d addr_reg:%b",$realtime,cnt, addr_reg)) 
    ##1 (cnt == add_cycle) 
    ##0 (1,$display("@%10t___ cnt: %d addr_reg:%h, addr_reg:%b",$realtime,cnt, addr_reg,addr_reg) ) 
    |-> (addr_m_send == addr_reg);
  endproperty
  AP_ADDR_eb: assert property (P_ADDR_eb(6));
  CP_ADDR_eb: cover property  (P_ADDR_eb(6));

  
endmodule 
module eth_commu
(
	input i_clk,i_rst_n,
	input [10:0] i_data_length,	
	input [7:0] i_pck_ident,i_pck_idx,
	input [7:0] i_cur_byte,									
	output reg o_get_cur_byte,
	input i_trig_send,
	output o_send_over,
	output reg [7:0] o_cmd,
	output reg [31:0] o_param,
	output reg o_cmd_come,
	
	inout io_eth_mdio,
	output o_eth_mdc,
	
	output o_eth_txen,
	output o_eth_txer,
	output [7:0] o_eth_txd,
	
	input i_eth_rxclk,
	input i_eth_rxdv,
	input i_eth_rxer,
	input [7:0] i_eth_rxd,
	input i_eth_crs,i_eth_col
);
	localparam UDP = 8'd17;
	localparam IPv4 = 16'h0800;
	localparam ARP = 16'h0806;
	localparam IPv4L = 8'h00;
	localparam ARPL = 8'h06;
	localparam INIT_LOCAL_MAC = 48'h_02_00_00_00_00_04;
	localparam INIT_DEST_MAC = 48'h_02_00_00_00_00_05;
	localparam INIT_LOCAL_IP = 32'h_C0_A8_01_04;
	localparam INIT_DEST_IP = 32'h_C0_A8_01_05;
	localparam PORT_NUMBER = 16'hFEEF;
	localparam UDP_LENGTH_OFFSET = 3'd4;
	localparam IP_TTL_OFFSET = 5'd8;
	localparam IP_PROT_OFFSET = 5'd9;
	localparam IP_SRCIP_OFFSET = 5'd12;
	localparam IP_DSTIP_OFFSET = 5'd16;
	localparam ETH_DSTMAC_OFFSET = 4'd0;
	localparam ETH_SRCMAC_OFFSET = 4'd6;
	localparam ETH_PROT_OFFSET = 4'd12;
	localparam ETHARP_SENDERMAC_OFFSET = 6'd22;
	localparam ETHARP_SENDERIP_OFFSET = 6'd28;
	localparam ETHARP_TARGETMAC_OFFSET = 6'd32;
	localparam ETHARP_TARGETIP_OFFSET = 6'd38;
	localparam ETHARP_HEAD_LENGTH = 6'd42;
	localparam ETH_HEAD_LENGTH = 5'd14;
	localparam IP_HEAD_LENGTH = 5'd20;
	localparam UDP_HEAD_LENGTH = 5'd8;
	
	localparam CMD_IP_SET_SRCIP = 2'd1;
	localparam CMD_IP_SET_DSTIP = 2'd2;
	
	localparam ST_IDEL = 10'd1;
	localparam ST_PREP_UDP = 10'd2;
	localparam ST_PREP_IP = 10'd4;
	localparam ST_SEND_DATA = 10'd8;
	localparam ST_SET_LOCAL_IP = 10'd16;
	localparam ST_SET_DEST = 10'd32;
	localparam ST_SEND_ARP = 10'd64;
	localparam ST_PREP_ARP = 10'd128;


	reg [7:0] udp_hdr [0:7];
	reg [7:0] ip_hdr [0:19];
	reg [7:0] eth_hdr [0:13];
	reg [7:0] etharp_hdr [0:41];
	reg [7:0] localip [0:3];
	reg [7:0] localmac [0:5];
	reg data_send_trig,data_send_req,send_over;
	reg [31:0] setted_ip;
	reg [47:0] setted_mac;
	reg [5:0] send_hdr_cnt;
	reg [3:0] send_hdr_sig;
	reg send_data_sig;
	
	reg ip_set_local,ip_set_dest;
	reg arp_set_local,eth_set_dst,arp_prep;
	reg [31:0] ip_ip;
	reg [47:0] eth_mac;
	reg set_local_sig,set_dest_sig;
	
	reg [9:0] state,state_next;
	reg arp_send_req,arp_trig,arp_trig0;
	reg set_local_req,set_local_trig,set_local_trig0;
	reg set_dest_req,set_dest_trig,set_dest_trig0;
	
	assign o_send_over = send_over;
	
	wire op_udp_ok;
	wire op_ip_ok;
	wire op_arp_ok;
	wire op_eth_ok;
	wire mac_send_ok;
	
	wire [2:0] udph_idx;
	wire [4:0] iph_idx;
	wire [3:0] eth_idx;
	wire [5:0] etharp_idx;
	wire [7:0] udph_byte,iph_byte,eth_byte,etharp_byte;
	wire wr_udph_en,wr_iph_en,wr_eth_en,wr_etharp_en;
	
	reg [5:0] arp_send_idx;
	
	udp udp_inst
	(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_trig(state == ST_PREP_UDP),
		.i_data_length(i_data_length + 2'd2),		//2 byte of packet_id
		.o_udph_idx(udph_idx),
		.o_udph_byte(udph_byte),
		.o_wr_udph_en(wr_udph_en),
		.o_ready(op_udp_ok)
	);
	
	ip ip_inst
	(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_trig(state == ST_PREP_IP),
		.i_data_length({udp_hdr[UDP_LENGTH_OFFSET],udp_hdr[UDP_LENGTH_OFFSET+1'd1]}),
		.i_ip0(ip_ip[31:24]),
		.i_ip1(ip_ip[23:16]),
		.i_ip2(ip_ip[15:8]),
		.i_ip3(ip_ip[7:0]),
		.i_set_local(ip_set_local),
		.i_set_dest(ip_set_dest),					
		.o_iph_idx(iph_idx),				
		.o_iph_byte(iph_byte),			
		.o_wr_iph_en(wr_iph_en),
		.o_ready(op_ip_ok)
	);
	
	eth eth_inst
	(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_mac0(eth_mac[47:40]),
		.i_mac1(eth_mac[39:32]),
		.i_mac2(eth_mac[31:24]),
		.i_mac3(eth_mac[23:16]),
		.i_mac4(eth_mac[15:8]),
		.i_mac5(eth_mac[7:0]),
		.i_set_dst(eth_set_dst),			
		.o_eth_idx(eth_idx),				
		.o_eth_byte(eth_byte),			
		.o_wr_eth_en(wr_eth_en),
		.o_ready(op_eth_ok)
	);
	
	etharp etharp
	(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_trig(state == ST_PREP_ARP),
		.i_ip0(ip_ip[31:24]),
		.i_ip1(ip_ip[23:16]),
		.i_ip2(ip_ip[15:8]),
		.i_ip3(ip_ip[7:0]),
		.i_mac0(eth_mac[47:40]),
		.i_mac1(eth_mac[39:32]),
		.i_mac2(eth_mac[31:24]),
		.i_mac3(eth_mac[23:16]),
		.i_mac4(eth_mac[15:8]),
		.i_mac5(eth_mac[7:0]),
		.i_set_local(arp_set_local),
		.o_hdr_idx(etharp_idx),				
		.o_hdr_byte(etharp_byte),
		.o_wr_hdr_en(wr_etharp_en),
		.o_ready(op_arp_ok)
	);
	
	reg mac_last_data;
	reg [7:0] mac_tx_data;
	reg [10:0] pdu_send_cnt_inc;
	
	wire mac_rx;
	wire [7:0] mac_rx_data;
	
	mac mac_inst
	(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_tx_trig(state == ST_SEND_DATA || state == ST_SEND_ARP),
		.i_last_data(mac_last_data),
		.i_data(mac_tx_data),
		.o_tx_over(mac_send_ok),
		.o_data(mac_rx_data),
		.o_rx(mac_rx),
		
		.io_eth_mdio(io_eth_mdio),
		.o_eth_mdc(o_eth_mdc),
		.o_eth_txen(o_eth_txen),
		.o_eth_txer(o_eth_txer),
		.o_eth_txd(o_eth_txd),
		.i_eth_rxclk(i_eth_rxclk),
		.i_eth_rxdv(i_eth_rxdv),
		.i_eth_rxer(i_eth_rxer),
		.i_eth_rxd(i_eth_rxd),
		.i_eth_crs(i_eth_crs),
		.i_eth_col(i_eth_col)
	);	
	
	always@(*)
	case(state)
	ST_IDEL:
		if(set_local_req)
			state_next = ST_SET_LOCAL_IP;
		else if(set_dest_req)
			state_next = ST_SET_DEST;
		else if(arp_send_req)
			state_next = ST_PREP_ARP;
		else if(data_send_req)
			state_next = ST_PREP_UDP;
		else
			state_next = ST_IDEL;
	ST_PREP_UDP:
		if(op_udp_ok)
			state_next = ST_PREP_IP;
		else
			state_next = ST_PREP_UDP;
	ST_PREP_IP:
		if(op_ip_ok)
			state_next = ST_SEND_DATA;
		else
			state_next = ST_PREP_IP;
	ST_PREP_ARP:
		if(op_arp_ok)
			state_next = ST_SEND_ARP;
		else
			state_next = ST_PREP_ARP;
	ST_SEND_DATA:
		if(mac_send_ok)
			state_next = ST_IDEL;
		else
			state_next = ST_SEND_DATA;
	ST_SEND_ARP:
		if(mac_send_ok)
			state_next = ST_IDEL;
		else
			state_next = ST_SEND_ARP;
	ST_SET_LOCAL_IP:
		if((op_ip_ok & op_arp_ok) | ((op_ip_ok ^ op_arp_ok) & set_local_sig))
			state_next = ST_IDEL;
		else
			state_next = ST_SET_LOCAL_IP;
	ST_SET_DEST:
		if((op_ip_ok & op_eth_ok) | ((op_ip_ok ^ op_eth_ok) & set_dest_sig))
			state_next = ST_IDEL;
		else
			state_next = ST_SET_DEST;
	default:
		state_next = ST_IDEL;
	endcase
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
		state <= ST_IDEL;
	else
		state <= state_next;
		
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		data_send_trig <= 0;
		arp_trig <= 0;
		set_local_trig <= 0;
		set_dest_trig <= 0;
		
		{udp_hdr[0],udp_hdr[1],udp_hdr[2],udp_hdr[3]} <= {PORT_NUMBER,PORT_NUMBER};
		{udp_hdr[6],udp_hdr[7]} <= 0;
		
		{ip_hdr[0],ip_hdr[1],ip_hdr[IP_TTL_OFFSET],ip_hdr[IP_PROT_OFFSET]} <= {8'h54,8'd0,8'd255,UDP};
		{ip_hdr[4],ip_hdr[5],ip_hdr[6],ip_hdr[7]} <= 0;
		
		{ip_hdr[IP_SRCIP_OFFSET],ip_hdr[IP_SRCIP_OFFSET+3'd1],ip_hdr[IP_SRCIP_OFFSET+3'd2],ip_hdr[IP_SRCIP_OFFSET+3'd3]} <= INIT_LOCAL_IP;
		
		{ip_hdr[IP_DSTIP_OFFSET],ip_hdr[IP_DSTIP_OFFSET+3'd1],ip_hdr[IP_DSTIP_OFFSET+3'd2],ip_hdr[IP_DSTIP_OFFSET+3'd3]} <= INIT_DEST_IP;
		
		{eth_hdr[ETH_SRCMAC_OFFSET],eth_hdr[ETH_SRCMAC_OFFSET+3'd1],eth_hdr[ETH_SRCMAC_OFFSET+3'd2],
			eth_hdr[ETH_SRCMAC_OFFSET+3'd3],eth_hdr[ETH_SRCMAC_OFFSET+3'd4],eth_hdr[ETH_SRCMAC_OFFSET+3'd5]} <= INIT_LOCAL_MAC;
			
		{eth_hdr[ETH_DSTMAC_OFFSET],eth_hdr[ETH_DSTMAC_OFFSET+3'd1],eth_hdr[ETH_DSTMAC_OFFSET+3'd2],
			eth_hdr[ETH_DSTMAC_OFFSET+3'd3],eth_hdr[ETH_DSTMAC_OFFSET+3'd4],eth_hdr[ETH_DSTMAC_OFFSET+3'd5]} <= INIT_DEST_MAC;
			
		{eth_hdr[ETH_PROT_OFFSET],eth_hdr[ETH_PROT_OFFSET+1'd1]} <= IPv4;
		
		{etharp_hdr[6],etharp_hdr[7],etharp_hdr[8],etharp_hdr[9],etharp_hdr[10],etharp_hdr[11]} <= INIT_LOCAL_MAC;			
		{etharp_hdr[ETH_PROT_OFFSET],etharp_hdr[ETH_PROT_OFFSET+1'd1]} <= ARP;
		{etharp_hdr[14],etharp_hdr[15]} <= 16'h1;
		{etharp_hdr[16],etharp_hdr[17]} <= 16'h0800;
		{etharp_hdr[18],etharp_hdr[19]} <= 16'h0604;
		{etharp_hdr[20],etharp_hdr[21]} <= 16'h1;
		{etharp_hdr[22],etharp_hdr[23],etharp_hdr[24],etharp_hdr[25],etharp_hdr[26],etharp_hdr[27]} <= INIT_LOCAL_MAC;
		{etharp_hdr[28],etharp_hdr[29],etharp_hdr[30],etharp_hdr[31]} <= INIT_LOCAL_IP;
	end
	else
	begin
		if(wr_udph_en)
			udp_hdr[udph_idx] <= udph_byte;
		if(wr_iph_en)
			ip_hdr[iph_idx] <= iph_byte;
		if(wr_eth_en)
			eth_hdr[eth_idx] <= eth_byte;
		if(wr_etharp_en)
			etharp_hdr[etharp_idx] <= etharp_byte;
			
		data_send_trig <= i_trig_send;
		arp_trig <= arp_trig0;
		set_local_trig <= set_local_trig0;
		set_dest_trig <= set_dest_trig0;
	end
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		send_over <= 0;
		arp_set_local <= 0;
		eth_set_dst <= 0;
		data_send_req <= 0;
		send_hdr_cnt <= 0;
		send_hdr_sig <= 0;
		send_data_sig <= 0;
		o_get_cur_byte <= 0;
		arp_send_req <= 0;
		set_local_req <= 0;
		set_dest_req <= 0;
	end
	else
	begin
		if(state == ST_SEND_DATA)
			data_send_req <= 0;
		else
			if(i_trig_send & !data_send_trig)
				data_send_req <= 1'd1;
			
		if(state == ST_SEND_ARP)
			arp_send_req <= 0;
		else
			if(arp_trig0 & !arp_trig)
				arp_send_req <= 1'd1;
			
		if(state == ST_SET_LOCAL_IP)
			set_local_req <= 0;
		else
			if(set_local_trig0 & !set_local_trig)
				set_local_req <= 1'd1;
			
		if(state == ST_SET_DEST)
			set_dest_req <= 0;
		else
			if(set_dest_trig0 & !set_dest_trig)
				set_dest_req <= 1'd1;
			
		case(state)
		ST_IDEL:
		begin
			send_over <= 0;
			arp_set_local <= 0;
			set_local_sig <= 0;
			set_dest_sig <= 0;
			ip_set_local <= 0;
			ip_set_dest <= 0;
			eth_set_dst <= 0;
			send_hdr_cnt <= 0;
			send_hdr_sig <= 0;
			send_data_sig <= 0;
			pdu_send_cnt_inc <= 1'd1;
		end
		ST_SET_LOCAL_IP:
		begin
			if(op_ip_ok ^ op_arp_ok)
				set_local_sig <= 1'd1;
			
			ip_set_local <= 1'd1;
			arp_set_local <= 1'd1;
			ip_ip <= setted_ip;
		end
		ST_SET_DEST:
		begin
			if(op_ip_ok ^ op_eth_ok)
				set_dest_sig <= 1'd1;
			
			ip_set_dest <= 1'd1;
			eth_set_dst <= 1'd1;
			ip_ip <= setted_ip;
			eth_mac <= setted_mac;
		end
		ST_PREP_ARP:
		begin				
			ip_ip <= setted_ip;
			eth_mac <= setted_mac;
			arp_send_idx <= 0;
		end
		ST_SEND_DATA:
		begin
			if(mac_send_ok)
				send_over <= 1'd1;
				
			if(pdu_send_cnt_inc == i_data_length)
				mac_last_data <= 1'd1;
			else
				mac_last_data <= 0;				
			
			if(!send_hdr_sig[0])
			begin
				if(send_hdr_cnt == ETH_HEAD_LENGTH-1'd1)
				begin
					send_hdr_cnt <= 0;
					send_hdr_sig[0] <= 1'd1;
				end
				else
					send_hdr_cnt <= send_hdr_cnt + 1'd1;
				
				mac_tx_data <= eth_hdr[send_hdr_cnt];
			end
			else if(!send_hdr_sig[1])
			begin
				if(send_hdr_cnt == IP_HEAD_LENGTH-1'd1)
				begin
					send_hdr_cnt <= 0;
					send_hdr_sig[1] <= 1'd1;
				end
				else
					send_hdr_cnt <= send_hdr_cnt + 1'd1;
				
				mac_tx_data <= ip_hdr[send_hdr_cnt];
			end
			else if(!send_hdr_sig[2])
			begin
				if(send_hdr_cnt == UDP_HEAD_LENGTH-1'd1)
				begin
					send_hdr_cnt <= 0;
					send_hdr_sig[2] <= 1'd1;
				end
				else
					send_hdr_cnt <= send_hdr_cnt + 1'd1;
				
				mac_tx_data <= udp_hdr[send_hdr_cnt];
			end
			else if(!send_hdr_sig[3])
			begin
				if(send_hdr_cnt == 1'd1)
				begin
					send_hdr_cnt <= 0;
					send_hdr_sig[3] <= 1'd1;
					o_get_cur_byte <= 1'd1;
				end
				else
					send_hdr_cnt <= send_hdr_cnt + 1'd1;
				
				mac_tx_data <= (send_hdr_cnt == 0 ? i_pck_ident : i_pck_idx);
			end
			else if(!send_data_sig)
			begin
				if(pdu_send_cnt_inc == i_data_length)
				begin
					send_data_sig <= 1'd1;
					o_get_cur_byte <= 0;
				end
				else
					pdu_send_cnt_inc <= pdu_send_cnt_inc + 1'd1;
					
				mac_tx_data <= i_cur_byte;					
			end
		end
		ST_SEND_ARP:
		begin				
			if(arp_send_idx == ETHARP_HEAD_LENGTH-1'd1)
				mac_last_data <= 1'd1;
			else
				mac_last_data <= 0;
			
			if(arp_send_idx != ETHARP_HEAD_LENGTH)
			begin
				mac_tx_data <= etharp_hdr[arp_send_idx];
				arp_send_idx <= arp_send_idx + 1'd1;
			end
		end
		endcase
	end
	
	localparam HEAD_SIZE = 6'd42;		//ETH + IP + UDP = ETH + ARP = 42
	localparam ETH_SIZE = 6'd14;		//ETH + IP + UDP = ETH + ARP = 42
	localparam CMD_SIZE = 6'd6;
	localparam BUFFER_COUNT = 4;
	localparam RX_CMD_SET_SERVER = 8'd0;
	localparam RX_CMD_SET_LOCAL = 8'd1;
	
	localparam ST_CACHE_DATA = 8'd2;
	localparam ST_PREPORC_DATA = 8'd4;
	localparam ST_PORC_ARP = 8'd8;
	localparam ST_PORC_CMD = 8'd16;
	localparam ST_PORC_END = 8'd32;
	
	reg [7:0] rxstate,rxstate_next;
	reg [7:0] rx_buf[0:(HEAD_SIZE+CMD_SIZE)*BUFFER_COUNT-1];
	reg [7:0] rx_bf_staddr[0:BUFFER_COUNT-1];
	reg [2:0] bfwr_idx,bfrd_idx;
	reg [7:0] bfwr_addr;
	reg [3:0] bfwr_cnt;
	reg bf_empty,bf_full,writing;
	
	wire wr = mac_rx & !bf_full;
	wire rd = (rxstate == ST_PORC_END);
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		rx_bf_staddr[0] <= 8'd0;
		rx_bf_staddr[1] <= 8'd1*(HEAD_SIZE+CMD_SIZE);
		rx_bf_staddr[2] <= 8'd2*(HEAD_SIZE+CMD_SIZE);
		rx_bf_staddr[3] <= 8'd3*(HEAD_SIZE+CMD_SIZE);
		bfwr_idx <= 0;
		bfrd_idx <= 0;
		bf_empty <= 1'd1;
		bf_full <= 0;
		bfwr_addr <= 0;
		writing <= 0;
	end
	else
	begin
		if(wr)
		begin
			writing <= 1'd1;
			if(bfwr_cnt != HEAD_SIZE+CMD_SIZE)
			begin
				rx_buf[bfwr_addr] <= mac_rx_data;
				bfwr_addr <= bfwr_addr + 1'd1;
				bfwr_cnt <= bfwr_cnt + 1'd1;
			end
		end
		
		if(!mac_rx & writing)
		begin
			writing <= 0;
			bfwr_idx <= bfwr_idx + 1'd1;
			bfwr_addr <= rx_bf_staddr[bfwr_idx[1:0] + 1'd1];
			bf_full <= (bfwr_idx + 1'd1) == {~bfrd_idx[2],bfrd_idx[1:0]};
		end
		
		if(rd)
		begin
			bfrd_idx <= bfrd_idx + 1'd1;
			bf_empty <= (bfrd_idx + 1'd1 == bfwr_idx);
		end
		
		if((!mac_rx & writing) & !rd)
			bf_empty <= 0;
		else if(rd & !(!mac_rx & writing))
			bf_full <= 0;
	end
	
	reg [7:0] cur_rx_data[0:HEAD_SIZE+CMD_SIZE-1];
	
	wire [7:0] layer3protL = cur_rx_data[ETH_PROT_OFFSET+1];
	wire rx_check_ok = (cur_rx_data[HEAD_SIZE] == ~cur_rx_data[HEAD_SIZE+1]);
	wire [7:0] rxcmd = cur_rx_data[HEAD_SIZE];
	wire [31:0] rxpara = {cur_rx_data[HEAD_SIZE+2],cur_rx_data[HEAD_SIZE+3],cur_rx_data[HEAD_SIZE+4],cur_rx_data[HEAD_SIZE+5]};
	wire [47:0] rxdstmac = {cur_rx_data[ETH_DSTMAC_OFFSET],cur_rx_data[ETH_DSTMAC_OFFSET+1],cur_rx_data[ETH_DSTMAC_OFFSET+2],
							cur_rx_data[ETH_DSTMAC_OFFSET+3],cur_rx_data[ETH_DSTMAC_OFFSET+4],cur_rx_data[ETH_DSTMAC_OFFSET+5]};
	wire [47:0] rxsrcmac = {cur_rx_data[ETH_SRCMAC_OFFSET],cur_rx_data[ETH_SRCMAC_OFFSET+1],cur_rx_data[ETH_SRCMAC_OFFSET+2],
							cur_rx_data[ETH_SRCMAC_OFFSET+3],cur_rx_data[ETH_SRCMAC_OFFSET+4],cur_rx_data[ETH_SRCMAC_OFFSET+5]};
	wire [31:0] rxsrcip = {cur_rx_data[ETH_SIZE+IP_SRCIP_OFFSET],cur_rx_data[ETH_SIZE+IP_SRCIP_OFFSET+1],
							cur_rx_data[ETH_SIZE+IP_SRCIP_OFFSET+2],cur_rx_data[ETH_SIZE+IP_SRCIP_OFFSET+3]};
	wire [31:0] rxarpsrcip = {cur_rx_data[28],cur_rx_data[29],cur_rx_data[30],cur_rx_data[31]};
	
	wire rx_check_mac = (rxdstmac == INIT_LOCAL_MAC) | &rxdstmac;
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
		rxstate <= ST_IDEL;
	else
		rxstate <= rxstate_next;
		
	always@(*)
	case(rxstate)
	ST_IDEL:
		if(!bf_empty)
			rxstate_next = ST_CACHE_DATA;
		else
			rxstate_next = ST_IDEL;
	ST_CACHE_DATA:
		rxstate_next = ST_PREPORC_DATA;
	ST_PREPORC_DATA:
	begin		
		if(rx_check_mac)
			if(layer3protL == ARPL)
				rxstate_next = ST_PORC_ARP;
			else if(layer3protL == IPv4L && rx_check_ok)
				rxstate_next = ST_PORC_CMD;
			else
				rxstate_next = ST_PORC_END;
		else
			rxstate_next = ST_PORC_END;
	end
	ST_PORC_CMD:
		rxstate_next = ST_PORC_END;
	ST_PORC_ARP:
		rxstate_next = ST_PORC_END;
	default:
		rxstate_next = ST_IDEL;
	endcase

	integer i;
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		arp_trig0 <= 0;
		o_cmd <= 0;
		o_param <= 0;
		o_cmd_come <= 0;
		set_local_trig0 <= 0;
		set_dest_trig0 <= 0;
	end
	else
	begin		
		case(rxstate)
		ST_CACHE_DATA:
			case(bfrd_idx[1:0])
			2'd0:
				for(i=0;i<HEAD_SIZE+CMD_SIZE;i=i+1)
					cur_rx_data[i] <= rx_buf[i];
			2'd1:
				for(i=0;i<HEAD_SIZE+CMD_SIZE;i=i+1)
					cur_rx_data[i] <= rx_buf[i+(HEAD_SIZE+CMD_SIZE)];
			2'd2:
				for(i=0;i<HEAD_SIZE+CMD_SIZE;i=i+1)
					cur_rx_data[i] <= rx_buf[i+(HEAD_SIZE+CMD_SIZE)*2];
			2'd3:
				for(i=0;i<HEAD_SIZE+CMD_SIZE;i=i+1)
					cur_rx_data[i] <= rx_buf[i+(HEAD_SIZE+CMD_SIZE)*3];
			endcase
		ST_PORC_ARP:
		begin
			arp_trig0 <= 1'd1;
			setted_ip <= rxarpsrcip;
			setted_mac <= rxsrcmac;
		end
		ST_PORC_CMD:
		begin
			if(rxcmd == RX_CMD_SET_LOCAL)
			begin
				set_local_trig0 <= 1'd1;
				setted_ip <= rxpara;
			end
			else if(rxcmd == RX_CMD_SET_SERVER)
			begin
				set_dest_trig0 <= 1'd1;
				setted_ip <= rxsrcip;
				setted_mac <= rxsrcmac;
			end
			else
			begin
				o_cmd <= rxcmd;
				o_param <= rxpara;
				o_cmd_come <= 1'd1;
			end
		end
		ST_PORC_END:
		begin
			arp_trig0 <= 0;
			set_local_trig0 <= 0;
			set_dest_trig0 <= 0;
			o_cmd_come <= 0;
		end
		endcase
	end
	
endmodule
 
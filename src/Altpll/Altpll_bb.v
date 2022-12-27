
module Altpll (
	altpll_100k_clk_clk,
	altpll_12m_clk_clk,
	clk_clk,
	reset_reset_n,
	uart_0_external_connection_rxd,
	uart_0_external_connection_txd);	

	output		altpll_100k_clk_clk;
	output		altpll_12m_clk_clk;
	input		clk_clk;
	input		reset_reset_n;
	input		uart_0_external_connection_rxd;
	output		uart_0_external_connection_txd;
endmodule

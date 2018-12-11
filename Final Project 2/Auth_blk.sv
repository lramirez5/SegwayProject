module Auth_blk(clk, rst_n, RX, rider_off, pwr_up);

  input clk, rst_n;
  input RX, rider_off;
  output logic pwr_up;
  wire [7:0] rx_data;
  wire rx_rdy;
  logic clr_rx_rdy;

  //SM variables
  typedef enum reg [1:0] {OFF, PWR1, PWR2}  state_t; 
  state_t state, nxt_state;

  localparam g = 8'h67;
  localparam s = 8'h73;

  //instantiate UART_rcv
  UART_rcv iRCV(.clk(clk), .rst_n(rst_n) , .RX(RX), .rdy(rx_rdy), .rx_data(rx_data), .clr_rdy(clr_rx_rdy));

  //SM flop
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      state <= OFF;
    else
      state <= nxt_state;

  //SM logic
  always_comb begin
    //default outputs
    nxt_state = OFF;
    pwr_up = 0;
    clr_rx_rdy = 0;
    case(state)

    OFF: if(rx_rdy && (rx_data == g)) begin
      clr_rx_rdy = 1;
      nxt_state = PWR1;
    end

    PWR1: begin pwr_up = 1;
    if(rx_rdy && (rx_data == s) && !rider_off) begin
      clr_rx_rdy = 1;
      nxt_state = PWR2;
    end
    else if(rx_rdy && (rx_data == s) && rider_off) begin
      nxt_state = OFF;
      clr_rx_rdy = 1;
    end 
    else nxt_state = PWR1;
    end

    PWR2: begin pwr_up = 1;
    if(rx_rdy && (rx_data == g)) begin
      clr_rx_rdy = 1;
      nxt_state = PWR1;
    end
    else if(!rider_off) nxt_state = PWR2;
    else clr_rx_rdy = 1;
    end

    default: nxt_state = OFF;
    endcase
  end

endmodule

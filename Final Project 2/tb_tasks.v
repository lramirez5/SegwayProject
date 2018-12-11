/* 
A file full of tasks to be called in the Segway_tb
We can add more as we figure out what would be helpful
*/

//initialize all signals and apply reset
task Initialize;
  begin
    clk = 0;
    cmd = 8'h00;
    send_cmd = 0;
    rider_lean = 14'h0000;
    RST_n = 0;
    @(negedge clk) RST_n = 1;
  end
endtask

//sends commands
//should be 'g' or 's'
task SendCmd;
  input reg [7:0] CMD;
  begin
    cmd = CMD;
    send_cmd = 1;
    @(posedge clk) send_cmd = 0;
  end
endtask

//test PID control system
//want to watch analog waveforms and see that it converges to zero
/*task PIDtest;
  begin
    rider_lean = 14'h1fff;  //max positive value
    repeat 1000000 @(posedge clk); 
    rider_lean = 14'h0000;  //set it back to zero
    repeat 1000000 @(posedge clk);  
  end
endtask */


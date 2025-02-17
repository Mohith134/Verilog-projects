`timescale 1ns / 1ps

module traffic_controller(north,south,east,west,clk,rst);

   output reg [2:0] north,south,east,west; //RYG == red bit, yellow bit, green bit
   input clk,rst;
 
   reg [2:0] state;
 
   parameter [2:0] north_green=3'b000;
   parameter [2:0] north_yellow=3'b001;
   parameter [2:0] south_green=3'b010;
   parameter [2:0] south_yellow=3'b011;
   parameter [2:0] east_green=3'b100;
   parameter [2:0] east_yellow=3'b101;
   parameter [2:0] west_green=3'b110;
   parameter [2:0] west_yellow=3'b111;

   reg [3:0] count;
 

   always @(posedge clk, posedge rst)
     begin
        if (rst)
            begin
                state=north_green;
                count = 0;
            end
        else
            begin
                case (state)
                north_green :
                    begin
                        if (count==12)
                            begin
                            count = 0;
                            state=north_yellow;
                            end
                        else
                            begin
                            count = count+1;
                            state=north_green;
                            end
                    end

                north_yellow :
                    begin
                        if (count==3)
                            begin
                            count=0;
                            state=south_green;
                            end
                        else
                            begin
                            count=count+1;
                            state=north_yellow;
                        end
                    end

               south_green :
                    begin
                        if (count==10)
                            begin
                            count=0;
                            state=south_yellow;
                            end
                        else
                            begin
                            count=count+1;
                            state=south_green;
                        end
                    end

            south_yellow :
                begin
                    if (count==3)
                        begin
                        count=0;
                        state=east_green;
                        end
                    else
                        begin
                        count=count+1;
                        state=south_yellow;
                        end
                    end

            east_green :
                begin
                    if (count==10)
                        begin
                        count=0;
                        state=east_yellow;
                        end
                    else
                        begin
                        count=count+1;
                        state=east_green;
                        end
                    end

            east_yellow :
                begin
                    if (count==2)
                        begin
                        count=0;
                        state=west_green;
                        end
                    else
                        begin
                        count=count+1;
                        state=east_yellow;
                        end
                    end

            west_green :
                begin
                    if (count==15)
                        begin
                        state=west_yellow;
                        count=0;
                        end
                    else
                        begin
                        count=count+1;
                        state=west_green;
                        end
                    end

            west_yellow :
                begin
                    if (count==5)
                        begin
                        state=north_green;
                        count=0;
                        end
                    else
                        begin
                        count=count+1;
                        state=west_yellow;
                        end
                    end
            endcase // case (state)
        end // always @ (state)
    end 


always @(state)
     begin
         case (state)
            north_green :
                begin
                    north = 3'b001;
                    south = 3'b100;
                    east = 3'b100;
                    west = 3'b100;
                end // case: north

            north_yellow :
                begin
                    north = 3'b010;
                    south = 3'b100;
                    east = 3'b100;
                    west = 3'b100;
                end // case: north_yellow

            south_green :
                begin
                    north = 3'b100;
                    south = 3'b001;
                    east = 3'b100;
                    west = 3'b100;
                end // case: south

            south_yellow :
                begin
                    north = 3'b100;
                    south = 3'b010;
                    east = 3'b100;
                    west = 3'b100;
                end // case: south_yellow

            west_green :
                begin
                    north = 3'b100;
                    south = 3'b100;
                    east = 3'b100;
                    west = 3'b001;
                end // case: west

            west_yellow :
                begin
                    north = 3'b100;
                    south = 3'b100;
                    east = 3'b100;
                    west = 3'b010;
                end // case: west_yellow

            east_green :
                begin
                    north = 3'b100;
                    south = 3'b100;
                    east = 3'b001;
                    west = 3'b100;
                end // case: east

            east_yellow :
                begin
                    north = 3'b100;
                    south = 3'b100;
                    east = 3'b010;
                    west = 3'b100;
                end // case: east_yellow
            endcase // case (state)
     end // always @ (state)
endmodule


//test bench

`timescale 1ns / 1ps

module traffic_controller_tb;

wire [2:0] north,south,east,west;
reg clk,rst;

traffic_controller DUT (north,south,east,west,clk,rst);

initial
 begin
  clk=1'b1;
  forever #5 clk=~clk;
 end
 
initial
 begin
  rst=1'b1;
  #50;
  rst=1'b0;
  #1000;
  $stop;
 end
endmodule

module MsPacman(
input CLOCK_50,
input [3:0] KEY,
input [9:0] SW,
output reg [9:0] LEDR,
output reg [6:0] HEX0,
output reg [6:0] HEX1,
output reg [6:0] HEX2,
output reg [6:0] HEX3,
output reg [14:0] positionX,
output reg [14:0] positionY
);


wire clk;
assign clk = CLOCK_50;

wire rst; 
assign rst = SW[0];

environment_interactions dotsnwalls(positionX,positionY,rst,clk,right_signal,left_signal,up_signal,down_signal,done_signal);
dots eatdots(positionX,positionY,rst,clk,done_signal);

reg [4:0]S;
reg [4:0]NS;

parameter START = 5'd0,
			 STAYSTILL = 5'd1,
			 MOVERIGHT = 5'd2,
			 MOVELEFT = 5'd3,
			 MOVEUP = 5'd4,
			 MOVEDOWN = 5'd5,
			 DONE = 5'd6,
			 ERROR = 5'd7;
			 
always@(posedge clk or negedge rst) 
begin
	if(rst == 1'b0)
	begin
		S <= START;
	end
	else 
	begin
		S <= NS;
	end 
end

always@(*)
begin
	case(S) 
	START: begin
				NS = STAYSTILL;
	end
	STAYSTILL: begin
					if (KEY[3] == 1'b0 && left_signal == 1'b0)
						NS = MOVELEFT;
					else if (KEY[2] == 1'b0 && up_signal == 1'b0)
						NS = MOVEUP;
					else if (KEY[1] == 1'b0 && down_signal == 1'b0)
						NS = MOVEDOWN;
					else if (KEY[0] == 1'b0 && right_signal == 1'b0)
						NS = MOVERIGHT;
					else if (done_signal == 1'b1)
						NS = DONE;
					else
						NS = STAYSTILL;
					end
	MOVERIGHT: begin
				if (KEY[0] == 1'b1)
						NS = STAYSTILL;
				  else
						NS = MOVERIGHT;
				end
	MOVELEFT: begin
				if (KEY[3] == 1'b1)
						NS = STAYSTILL;
				  else
						NS = MOVELEFT;
				end
	MOVEUP: begin
				if (KEY[2] == 1'b1)
						NS = STAYSTILL;
				  else
						NS = MOVEUP;
				end
	MOVEDOWN: begin
				if (KEY[1] == 1'b1)
						NS = STAYSTILL;
				  else
						NS = MOVEDOWN;
				end
	default: NS = ERROR;
	endcase
end

always@(posedge clk or negedge rst) 
begin
	if(rst == 1'b0) 
	begin 
		LEDR <= 10'd0;
		positionX <= 15'd0; 
		positionY <= 15'd0;
	end
    else
	 case(S)
			START: 
			begin
				LEDR <= 10'd0;
				positionX <= 15'd0; //change to origin
				positionY <= 15'd0; //change to origin
			end 
			STAYSTILL:
			begin
				LEDR[0] <= 1'b0;
				LEDR[1] <= 1'b0;
				LEDR[2] <= 1'b0;
				LEDR[3] <= 1'b0;
				LEDR[9] <= 1'b1;
			end
			MOVERIGHT: 
			begin
				LEDR[0] <= 1'b1;
				LEDR[1] <= 1'b0;
				LEDR[2] <= 1'b0;
				LEDR[3] <= 1'b0;
				LEDR[9] <= 1'b0;
				positionX <= positionX + 1'b1;
			end
			MOVELEFT:
			begin
				LEDR[0] <= 1'b0;
				LEDR[1] <= 1'b0;
				LEDR[2] <= 1'b0;
				LEDR[3] <= 1'b1;
				LEDR[9] <= 1'b0;
				positionX <= positionX - 1'b1;
			end
			MOVEUP:
			begin
				LEDR[0] <= 1'b0;
				LEDR[1] <= 1'b0;
				LEDR[2] <= 1'b1;
				LEDR[3] <= 1'b0;
				LEDR[9] <= 1'b0;
				positionY <= positionY + 1'b1;
			end
			MOVEDOWN:
			begin 
				LEDR[0] <= 1'b0;
				LEDR[1] <= 1'b1;
				LEDR[2] <= 1'b0;
				LEDR[3] <= 1'b0;
				LEDR[9] <= 1'b0;
				positionY <= positionY + 1'b1;
			end
			endcase
end			
endmodule



module environment_interactions(
input [14:0] positionX,
input [14:0] positionY,
input rst,
input clk,
input done_signal,
output reg right_signal,
output reg left_signal,
output reg up_signal,
output reg down_signal
);

reg [4:0] mux_address;
reg [4:0] input_data;
reg write;
wire [4:0] output_data;

wall_and_dot_mem game_memory(
   .address(mux_address),
   .clock(clk),
   .data(input_data),
   .wren(write),
   .q(output_data)
);

reg [1:0] select_path;

//MUX memory to read and write at different times 
always @(*)
begin
    case (select_path)
        2'd0:
				/* read only for wall interactions*/ 
            begin
                mux_address = read_address[4:0];
                input_data = 5'd0;
                write = 1'b0;
            end
		  2'd1:
				/* write for eating dots */ 
				begin
                mux_address = write_address[4:0];
                input_data = write_data_in[4:0];
                write = write_change;
            end
        default:
            begin
                mux_address = 5'd0;
                input_data = 5'd0;
                write = 1'b0;
            end
    endcase
end

reg [4:0]read_address;
reg [4:0]write_address;
reg [4:0]write_data_in;

reg write_change; 

reg [2:0] width;

reg [4:0]S;
reg [4:0]NS;

parameter S_START = 5'd0,
			 GOODTOGO = 5'd1,
			 NORTH_WALL = 5'd2,
			 SOUTH_WALL = 5'd3,
			 EAST_WALL = 5'd4,
			 WEST_WALL = 5'd5,
			 S_DONE = 5'd6,
			 ERROR = 5'd7;

always@(posedge clk or negedge rst) 
begin
	if(rst == 1'b0)
	begin
		S <= S_START;
	end
	else 
	begin
		S <= NS;
	end 
end


always@(*)
begin
	case(S) 
	S_START: 
	begin
		NS = GOODTOGO;
	end
	GOODTOGO: 
	begin
		if (output_data[4] == 1'b1)
			NS = NORTH_WALL;
		else if (output_data[3] == 1'b1)
			NS = EAST_WALL;
		else if (output_data[2] == 1'b1)
			NS = SOUTH_WALL;
		else if (output_data[1] == 1'b1)
			NS = WEST_WALL;
		else if (done_signal == 1'b1)
			NS = S_DONE;
		else
			NS = GOODTOGO;
	end
	NORTH_WALL:
	begin
		if (output_data[4] == 1'b1)
			NS = NORTH_WALL;
		else
			NS = GOODTOGO;
	end
	SOUTH_WALL:
	begin
		if (output_data[2] == 1'b1)
			NS = SOUTH_WALL;
		else
			NS = GOODTOGO;
	end
	EAST_WALL:
	begin
		if (output_data[3] == 1'b1)
			NS = EAST_WALL;
		else
			NS = GOODTOGO;
	end
	WEST_WALL:
	begin
		if (output_data[1] == 1'b1)
			NS = WEST_WALL;
		else
			NS = GOODTOGO;
	end
	S_DONE:
	begin
		NS = S_DONE;
	end
	default: NS = ERROR;
	endcase
end



always@(posedge clk or negedge rst) 
begin
	if(rst == 1'b0) 
	begin 
		read_address <= 5'd0;
		write_address <= 5'd0;
		write_data_in <= 5'd0;
		write_change <= 1'b0;
		select_path <= 2'd0;
		right_signal <= 1'b0;
		left_signal <= 1'b0;
		up_signal <= 1'b0;
		down_signal <= 1'b0;
	end
    else
	 case(S)
			S_START: 
				begin
					read_address <= 5'd0;
					write_address <= 5'd0;
					write_data_in <= 5'd0;
					write_change <= 1'b0;
					select_path <= 2'd0;
					right_signal <= 1'b0;
					left_signal <= 1'b0;
					up_signal <= 1'b0;
					down_signal <= 1'b0;
				end
			GOODTOGO:
				begin
					select_path <= 2'd0;
					width = 3'd8;
					read_address <= (positionY * width + positionX);//equation to calculate coordinates
					right_signal <= 1'b0;
					left_signal <= 1'b0;
					up_signal <= 1'b0;
					down_signal <= 1'b0;
				end
			NORTH_WALL:
				begin
					select_path <= 2'd0;
					up_signal <= 1'b1;
				end
			SOUTH_WALL:
				begin
					select_path <= 2'd0;
					down_signal <= 1'b1;
				end
			EAST_WALL:
				begin
					select_path <= 2'd0;
					right_signal <= 1'b1;
				end
			WEST_WALL:
				begin
					select_path <= 2'd0;
					left_signal <= 1'b1;
				end
	endcase
end 
endmodule

module dots(
input [14:0] positionX,
input [14:0] positionY,
input rst,
input clk,
input [4:0]output_data,
input [4:0]read_address,
output reg select_path,
output reg [4:0]write_address,
output reg [4:0]write_data_in,
output reg write_change, 
output reg done_signal);
reg [4:0] i;

reg [4:0]S_DOTS;
reg [4:0]NS;

parameter DOTS_START = 5'd0,
			 LOOK_FOR_DOTS = 5'd1,
			 EATDOTS = 5'd2,
			 DOTS_DONE = 5'd3,
			 FOR_COND = 5'd4,
			 S_ERROR = 5'd7;

always@(posedge clk or negedge rst) 
begin
	if(rst == 1'b0)
	begin
		S_DOTS <= DOTS_START;
	end
	else 
	begin
		S_DOTS <= NS;
	end 
end


always@(*)
begin
	case(S_DOTS) 
	DOTS_START: 
	begin
		NS = FOR_COND;
	end
	FOR_COND:
	begin
		if (i < 24)
			NS = LOOK_FOR_DOTS;
		else
			NS = DOTS_DONE;
	end
	LOOK_FOR_DOTS:
	begin
		if (output_data[0] == 1'b1)
			NS = EATDOTS;
		else
			NS = LOOK_FOR_DOTS;
	end
	EATDOTS:
	begin 
		NS = LOOK_FOR_DOTS;
	end
	DOTS_DONE:
	begin
		NS = DOTS_DONE;
	end
	default: NS = S_ERROR;
	endcase
end
	
always@(posedge clk or negedge rst) 
begin
	if(rst == 1'b0) 
	begin 
		i <= 1'b0;
		done_signal <= 1'b0;
	end
    else
	 case(S_DOTS)
			DOTS_START: 
				begin
				end
			EATDOTS:
			begin
				i <= i + 1'b1;
				select_path <= 2'd1;
				write_address <= read_address;
            write_data_in[0] <= 1'b0;
            write_change <= 1'b1;
			end
			DOTS_DONE:
			begin
				done_signal <= 1'b1;
			end
	endcase
end	
endmodule

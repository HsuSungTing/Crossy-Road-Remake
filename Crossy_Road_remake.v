module Lab5_debounce(clk_debounce,sig_in,sig_out);
    input clk_debounce,sig_in;
    output sig_out;
    reg q1,q2,q3;
    always@(posedge clk_debounce)begin
        q1<=sig_in;
        q2<=q1;
        q3<=q2;
    end
    assign sig_out=q1&q2&(!q3);
endmodule

module main(clk,S4,S3,S0,reset,vga_r, vga_g, vga_b,hSync,vSync,LED,segment,enable);
    //player->chicken_rom car truck brick bigtruck
    input clk,reset,S4,S3,S0;//pclk式螢幕的clk
    output reg[0:15]LED;
    output reg[7:0]segment;
    output reg[3:0]enable;
    output hSync,vSync;
    output [3:0] vga_r,vga_g,vga_b;
    wire pclk;
    wire dataValid;
    wire [9:0]h_cnt,v_cnt;//螢幕counter
    reg [11:0]vga_data;

    wire go_up,go_right,go_left;
    Lab5_debounce u0(.clk_debounce(clk_debounce),.sig_in(S4),.sig_out(go_up));
    Lab5_debounce u1(.clk_debounce(clk_debounce),.sig_in(S3),.sig_out(go_left));
    Lab5_debounce u2(.clk_debounce(clk_debounce),.sig_in(S0),.sig_out(go_right));
//----------處理rom-------------

    reg [13:0]rom_addr[4:0];//64*64-> brick_rom
    wire [11:0]rom_dout[4:0];

    //0 brick
    block_rom uu0(.clka(pclk),.addra(rom_addr[0]),.douta(rom_dout[0]));
    //1 player
    chicken_rom uu1(.clka(pclk),.addra(rom_addr[1]),.douta(rom_dout[1]));
    //2 car
    car_rom uu2(.clka(pclk),.addra(rom_addr[2]),.douta(rom_dout[2]));
    //3 truck
    truck_rom uu3(.clka(pclk),.addra(rom_addr[3]),.douta(rom_dout[3]));
    //4 big truck
    big_truck_rom uu4(.clka(pclk),.addra(rom_addr[4]),.douta(rom_dout[4]));
    
    //---------------------------------------------
    
    dcm_25M_this uuu0(.clk_in1(clk),.clk_out1(pclk),.reset(!reset));
    SyncGeneration U0(.pclk(pclk),.reset(reset),.hSync(hSync),.vSync(vSync),.dataValid(dataValid),.hDataCnt(h_cnt),.vDataCnt(v_cnt));
    
    //-----brick的判定----不會動------
    wire [0:4]brick_area;
    //-----------------------
    assign brick_area[0]=((h_cnt>=10'd8)&(h_cnt<=10'd8+10'd64)&(v_cnt>=10'd8)&(v_cnt<=10'd8+10'd64))?1'b1:1'b0;
    assign brick_area[1]=((h_cnt>=10'd168)&(h_cnt<=10'd168+10'd64)&(v_cnt>=10'd8)&(v_cnt<=10'd8+10'd64))?1'b1:1'b0;
    assign brick_area[2]=((h_cnt>=10'd248)&(h_cnt<=10'd248+10'd64)&(v_cnt>=10'd8)&(v_cnt<=10'd8+10'd64))?1'b1:1'b0;
    assign brick_area[3]=((h_cnt>=10'd408)&(h_cnt<=10'd408+10'd64)&(v_cnt>=10'd8)&(v_cnt<=10'd8+10'd64))?1'b1:1'b0;
    assign brick_area[4]=((h_cnt>=10'd488)&(h_cnt<=10'd488+10'd64)&(v_cnt>=10'd8)&(v_cnt<=10'd8+10'd64))?1'b1:1'b0;
    assign brick_bool=(brick_area[0]||brick_area[1]||brick_area[2]||brick_area[3]||brick_area[4]);
    //--------player判定-------會動-----------
    reg [9:0]player_pos_x;
    reg [9:0]player_pos_y;
    wire player_bool;
    assign player_bool=((h_cnt>=player_pos_x)&(h_cnt<=player_pos_x+10'd64)&(v_cnt>=player_pos_y)&(v_cnt<=player_pos_y+10'd64))?1'b1:1'b0;
    
    //--------car的判定----
    reg [9:0]car_1_pos_x,car_2_pos_x,car_3_pos_x,car_pos_y;
    wire [0:2]car_area;
    wire car_bool;
    assign car_area[0]=((h_cnt>=car_1_pos_x)&(h_cnt<=car_1_pos_x+10'd64)&(v_cnt>=car_pos_y)&(v_cnt<=car_pos_y+10'd64))?1'b1:1'b0;
    assign car_area[1]=((h_cnt>=car_2_pos_x)&(h_cnt<=car_2_pos_x+10'd64)&(v_cnt>=car_pos_y)&(v_cnt<=car_pos_y+10'd64))?1'b1:1'b0;
    assign car_area[2]=((h_cnt>=car_3_pos_x)&(h_cnt<=car_3_pos_x+10'd64)&(v_cnt>=car_pos_y)&(v_cnt<=car_pos_y+10'd64))?1'b1:1'b0;
    assign car_bool=(car_area[0]||car_area[1]||car_area[2]);

    //--------------truck---共三台-------------------
    reg [9:0]truck_1_pos_x,truck_2_pos_x,truck_3_pos_x,truck_pos_y;
    wire [0:2]truck_area;
    assign truck_area[0]=((h_cnt>=truck_1_pos_x)&(h_cnt<=truck_1_pos_x+10'd128)&(v_cnt>=truck_pos_y)&(v_cnt<=truck_pos_y+10'd64))?1'b1:1'b0;
    assign truck_area[1]=((h_cnt>=truck_2_pos_x)&(h_cnt<=truck_2_pos_x+10'd128)&(v_cnt>=truck_pos_y)&(v_cnt<=truck_pos_y+10'd64))?1'b1:1'b0;
    assign truck_area[2]=((h_cnt>=truck_3_pos_x)&(h_cnt<=truck_3_pos_x+10'd128)&(v_cnt>=truck_pos_y)&(v_cnt<=truck_pos_y+10'd64))?1'b1:1'b0;
    
    reg [9:0]truck_1_head_x,truck_2_head_x,truck_3_head_x;
    wire [0:2]truck_head_area;
    reg [0:2]truck_head_bool;
    assign truck_head_area[0]=(truck_head_bool[0]&(h_cnt>=10'd0)&(h_cnt<=10'd0+10'd64)&(v_cnt>=truck_pos_y)&(v_cnt<=truck_pos_y+10'd64))?1'b1:1'b0;
    assign truck_head_area[1]=(truck_head_bool[1]&(h_cnt>=10'd0)&(h_cnt<=10'd0+10'd64)&(v_cnt>=truck_pos_y)&(v_cnt<=truck_pos_y+10'd64))?1'b1:1'b0;
    assign truck_head_area[2]=(truck_head_bool[2]&(h_cnt>=10'd0)&(h_cnt<=10'd0+10'd64)&(v_cnt>=truck_pos_y)&(v_cnt<=truck_pos_y+10'd64))?1'b1:1'b0;
    //各自assign truck_head_bool 然後sync掃到且該地方出現head(三取一)，->assign rom_addr
    
    wire truck_bool;
    assign truck_bool=(truck_area[0]||truck_area[1]||truck_area[2]||truck_head_area[0]||truck_head_area[1]||truck_head_area[2]);
    //-------big_truck---共三台------------
    reg [9:0]big_truck_1_pos_x,big_truck_2_pos_x,big_truck_pos_y;
    wire [0:1]big_truck_area;
    assign big_truck_area[0]=((h_cnt>=big_truck_1_pos_x)&(h_cnt<=big_truck_1_pos_x+10'd192)&(v_cnt>=big_truck_pos_y)&(v_cnt<=big_truck_pos_y+10'd64))?1'b1:1'b0;
    assign big_truck_area[1]=((h_cnt>=big_truck_2_pos_x)&(h_cnt<=big_truck_2_pos_x+10'd192)&(v_cnt>=big_truck_pos_y)&(v_cnt<=big_truck_pos_y+10'd64))?1'b1:1'b0;
    wire big_truck_bool;
    
    
    reg big_truck_mid_bool[0:1];
    reg big_truck_tail_bool[0:1];
    wire big_truck_mid_area[0:1];
    wire big_truck_tail_area[0:1];
    
    assign big_truck_mid_area[0]=(big_truck_mid_bool[0]&&(h_cnt>=10'd0)&&(h_cnt<=10'd128)&&(v_cnt>=big_truck_pos_y)&(v_cnt<=big_truck_pos_y+10'd64));
    assign big_truck_mid_area[1]=(big_truck_mid_bool[1]&&(h_cnt>=10'd0)&&(h_cnt<=10'd128)&&(v_cnt>=big_truck_pos_y)&(v_cnt<=big_truck_pos_y+10'd64));
    
    assign big_truck_tail_area[0]=(big_truck_tail_bool[0]&&(h_cnt>=10'd0)&&(h_cnt<=10'd64)&&(v_cnt>=big_truck_pos_y)&(v_cnt<=big_truck_pos_y+10'd64));
    assign big_truck_tail_area[1]=(big_truck_tail_bool[1]&&(h_cnt>=10'd0)&&(h_cnt<=10'd64)&&(v_cnt>=big_truck_pos_y)&(v_cnt<=big_truck_pos_y+10'd64));
    assign big_truck_bool=(big_truck_area[0]||big_truck_area[1]||big_truck_mid_area[0]||big_truck_mid_area[1]||big_truck_tail_area[0]||big_truck_tail_area[1]);
    //---------藍色車道---------
    wire blue_bool,orange_bool;
    assign blue_bool=((v_cnt>=10'd80)&(v_cnt<=10'd160))?1'b1:1'b0;

    //---------橘色車道-------------
    assign orange_bool=((v_cnt>=10'd240)&(v_cnt<=10'd400))?1'b1:1'b0;
    
    //---------虛線部分-------------
    reg line_x_bool,line_y_bool;
    always@(*)begin
        if((h_cnt>=10'd79&&h_cnt<=10'd81)||(h_cnt>=10'd159&&h_cnt<=10'd161)||(h_cnt>=10'd239&&h_cnt<=10'd241)||(h_cnt>=10'd319&&h_cnt<=10'd321))begin
            if(v_cnt[2:0]==3'b111||v_cnt[2:0]==3'b110)line_x_bool=0;
            else line_x_bool=1;
        end
        else if((h_cnt>=10'd399&&h_cnt<=10'd401)||(h_cnt>=10'd479&&h_cnt<=10'd481)||(h_cnt>=10'd559&&h_cnt<=10'd561))begin
            if(v_cnt[2:0]==3'b111||v_cnt[2:0]==3'b110)line_x_bool=0;
            else line_x_bool=1;
        end
        else line_x_bool=0;
    end

    always@(*)begin
        if((v_cnt>=10'd79&&v_cnt<=10'd81)||(v_cnt>=10'd159&&v_cnt<=10'd161)||(v_cnt>=10'd239&&v_cnt<=10'd241)||(v_cnt>=10'd319&&v_cnt<=10'd321))begin
            if(h_cnt[2:0]==3'b111||h_cnt[2:0]==3'b110)line_y_bool=0;
            else line_y_bool=1;
        end
        else if((v_cnt>=10'd399&&v_cnt<=10'd401))begin
            if(h_cnt[2:0]==3'b111||h_cnt[2:0]==3'b110)line_y_bool=0;
            else line_y_bool=1;
        end
        else line_y_bool=0;
    end
    //-----------外框線-----------
    reg out_line_bool;
    always@(*)begin
        if((h_cnt>=10'd0&&h_cnt<=10'd5)||(h_cnt>=10'd634&&h_cnt<=10'd640))begin
            out_line_bool=1;
        end
        else if((v_cnt>=10'd0&&v_cnt<=10'd5)||(v_cnt>=10'd474&&v_cnt<=10'd480))begin
            out_line_bool=1;
        end
        else out_line_bool=0;
    end
    
    //rom_addr的賦值
    always@(posedge pclk,negedge reset)begin
        if (!reset) begin
            rom_addr[0]<=14'd0;
            rom_addr[1]<=14'd0;
            rom_addr[2]<=14'd0;
            rom_addr[3]<=14'd0;
            rom_addr[4]<=14'd0;
        end
        else begin
            if (dataValid==1'b1) begin // send data
                if(player_bool==1)begin
                    rom_addr[1]<=(v_cnt-player_pos_y)*64+(h_cnt-player_pos_x);
                end
                else if(brick_bool==1)begin
                    if(brick_area[0])
                        rom_addr[0]<=(v_cnt-10'd8)*64+(h_cnt-10'd8);
                    else if(brick_area[1])
                        rom_addr[0]<=(v_cnt-10'd8)*64+(h_cnt-10'd168);
                    else if(brick_area[2])
                        rom_addr[0]<=(v_cnt-10'd8)*64+(h_cnt-10'd248);
                    else if(brick_area[3])
                        rom_addr[0]<=(v_cnt-10'd8)*64+(h_cnt-10'd408);
                    else 
                        rom_addr[0]<=(v_cnt-10'd8)*64+(h_cnt-10'd488);
                end
                
                else if(car_bool)begin 
                    if(car_area[0]==1)
                        rom_addr[2]<=(v_cnt-car_pos_y)*64+(h_cnt-car_1_pos_x);
                    else if(car_area[1]==1)
                        rom_addr[2]<=(v_cnt-car_pos_y)*64+(h_cnt-car_2_pos_x);
                    else 
                        rom_addr[2]<=(v_cnt-car_pos_y)*64+(h_cnt-car_3_pos_x);
                end
                else if(truck_bool)begin//128*64
                    if(truck_area[0])
                        rom_addr[3]<=(v_cnt-truck_pos_y)*128+(h_cnt-truck_1_pos_x);
                    else if(truck_area[1])
                        rom_addr[3]<=(v_cnt-truck_pos_y)*128+(h_cnt-truck_2_pos_x);
                    else if(truck_area[2])
                        rom_addr[3]<=(v_cnt-truck_pos_y)*128+(h_cnt-truck_3_pos_x);
                    //---------------------------------------------
                    else if(truck_head_area[0])
                        rom_addr[3]<=(v_cnt-truck_pos_y)*128+(h_cnt-10'd0)+10'd64;
                    else if(truck_head_area[1])
                        rom_addr[3]<=(v_cnt-truck_pos_y)*128+(h_cnt-10'd0)+10'd64;
                    else 
                        rom_addr[3]<=(v_cnt-truck_pos_y)*128+(h_cnt-10'd0)+10'd64;
                end
                else if(big_truck_bool)begin//128*64
                    if(big_truck_area[0])
                        rom_addr[4]<=(v_cnt-big_truck_pos_y)*192+(h_cnt-big_truck_1_pos_x);
                    else if(big_truck_area[1])
                        rom_addr[4]<=(v_cnt-big_truck_pos_y)*192+(h_cnt-big_truck_2_pos_x);
                    else if(big_truck_mid_area[0])
                        rom_addr[4]<=(v_cnt-big_truck_pos_y)*192+(h_cnt)+10'd64;
                    else if(big_truck_mid_area[1])
                        rom_addr[4]<=(v_cnt-big_truck_pos_y)*192+(h_cnt)+10'd64;
                    else if(big_truck_tail_area[0])
                        rom_addr[4]<=(v_cnt-big_truck_pos_y)*192+(h_cnt)+10'd128;
                    else 
                        rom_addr[4]<=(v_cnt-big_truck_pos_y)*192+(h_cnt)+10'd128;
                end
                else begin 
                        rom_addr[0]<=rom_addr[0];
                        rom_addr[1]<=rom_addr[1];
                        rom_addr[2]<=rom_addr[2];
                        rom_addr[3]<=rom_addr[3];
                        rom_addr[4]<=rom_addr[4];
                    end
                end
            else begin
                rom_addr[0]<=rom_addr[0];
                rom_addr[1]<=rom_addr[1];
                rom_addr[2]<=rom_addr[2];
                rom_addr[3]<=rom_addr[3];
                rom_addr[4]<=rom_addr[4];
            end
        end
    end

    //rom_addr的賦值
    always@(posedge pclk,negedge reset)begin
        if (!reset) begin
            vga_data<=12'h000;
        end
        else begin
            if (dataValid==1'b1) begin // send data
                if(player_bool==1)begin
                    vga_data<=rom_dout[1];
                end
                else if(brick_bool==1)begin
                    vga_data<=rom_dout[0];
                end
                else if(car_bool==1)begin
                    vga_data<=rom_dout[2];
                end
                else if(truck_bool==1)begin
                    vga_data<=rom_dout[3];
                end
                else if(big_truck_bool==1)begin
                    vga_data<=rom_dout[4];
                end
                else if(line_x_bool)begin
                    vga_data<=12'h000;
                end
                else if(line_y_bool)begin
                    vga_data<=12'h000;
                end
                else if(out_line_bool)begin
                    vga_data<=12'h08f;
                end
                else begin 
                        if(blue_bool) vga_data<=12'h08f;
                        else if(orange_bool) vga_data<=12'hf80;
                        else vga_data<=12'hfff;
                    end
                end
            else begin
                vga_data<=12'h000;
            end
        end
    end

//-----------------FSM----------------------
    reg [1:0]state,nextstate;
    wire clk_1HZ;
    parameter Move=2'd0,Die=2'd1,Win=2'd2;
    reg in_brick_bool,hit_by_car_bool,destination_bool;
    //FSM是控制車子和palyer 都用1Hz
    always@(posedge clk_debounce,negedge reset)begin//next state register
        if(!reset) state<=Move;
        else state<=nextstate;
    end
    //next state logic
    always@(*)begin
        case (state)
            Move:begin
                if(in_brick_bool||hit_by_car_bool)nextstate=Die;
                else if(destination_bool)nextstate=Win;
                else nextstate=Move;
            end
            Die:nextstate=Die;
            Win:nextstate=Win;
            default: nextstate=Move;
        endcase
    end
//--------判定相撞--------
    always@(*)begin
        if(player_bool&&car_bool)hit_by_car_bool=1;
        else if(player_bool&&truck_bool)hit_by_car_bool=1;
        else if(player_bool&&big_truck_bool)hit_by_car_bool=1;
        else hit_by_car_bool=0;
    end
//---------判定進入磚塊-----------
    always@(*)begin
        if(player_bool&&brick_bool)in_brick_bool=1;
        else in_brick_bool=0;
    end
//-------判定勝利-----------
    always@(*)begin
        if(player_pos_y>10'd0&&player_pos_y<10'd80)begin
            if(player_pos_x>10'd80&&player_pos_x<10'd160) destination_bool=1;
            else if(player_pos_x>10'd320&&player_pos_x<10'd400) destination_bool=1;
            else if(player_pos_x>10'd560&&player_pos_x<10'd640) destination_bool=1;
            else destination_bool=0;
        end
        else destination_bool=0;
    end
//-------------------------

    reg [3:0]total_step_dec;
    reg [3:0]total_step_digit;

//----------控制累計步數----只有Move才會動--------------
    always@(posedge clk_debounce,negedge reset)begin
        if(!reset)begin
            total_step_dec<=4'd0;
            total_step_digit<=4'd0;
        end
        else if(state==Move)begin
            if((go_left&&player_pos_x>10'd80)||(go_right&&player_pos_x<10'd560)||(go_up&&player_pos_y>10'd80))begin
                if(total_step_digit<4'd9)begin
                    total_step_digit<=total_step_digit+1'd1;
                    total_step_dec<=total_step_dec;
                end
                else begin
                    total_step_digit<=4'd0;
                    total_step_dec<=total_step_dec+1'd1;
                end
            end
            else begin
                total_step_digit<=total_step_digit;
                total_step_dec<=total_step_dec;
            end
        end
        else begin
            total_step_digit<=total_step_digit;
            total_step_dec<=total_step_dec;
        end
    end

    //-------------------------
    always@(posedge clk_debounce,negedge reset)begin
        if(!reset) begin
            player_pos_y<=10'd408;//static
            player_pos_x<=10'd248;
        end
        else if(state==Move)begin
            if(go_left&&player_pos_x>10'd80)begin
                player_pos_x<=player_pos_x-10'd80;
                player_pos_y<=player_pos_y;
            end
            else if(go_right&&player_pos_x<10'd560)begin
                player_pos_x<=player_pos_x+10'd80;
                player_pos_y<=player_pos_y;
            end
            else if(go_up&&player_pos_y>10'd80)begin
                player_pos_x<=player_pos_x;
                player_pos_y<=player_pos_y-10'd80;
            end
            else begin
                player_pos_y<=player_pos_y;//static
                player_pos_x<=player_pos_x;
            end
        end
        else begin
            player_pos_y<=player_pos_y;//static
            player_pos_x<=player_pos_x;
        end
    end
    
    wire clk_05HZ;
    //---------------讓big truck動--------------
    always@(posedge clk_05HZ,negedge reset)begin
        if(!reset)begin
            big_truck_pos_y<=10'd88;
            big_truck_1_pos_x<=10'd24;
            big_truck_2_pos_x<=10'd424;
            big_truck_mid_bool[0]<=0;big_truck_mid_bool[1]<=0;
            big_truck_tail_bool[0]<=0;big_truck_tail_bool[1]<=0;
        end
        else if(state==Move)begin
            if(10'd320<big_truck_2_pos_x-10'd80&&big_truck_2_pos_x-10'd80<10'd400)begin
                //case 1 //下一步truck1要超出去 (320<truck2_pos_x-80<400)
                //mid_body_bool_1=1;
                big_truck_1_pos_x<=big_truck_1_pos_x-10'd80;
                big_truck_mid_bool[0]<=1;big_truck_mid_bool[1]<=0;
                big_truck_tail_bool[0]<=0;big_truck_tail_bool[1]<=0;
                big_truck_2_pos_x<=big_truck_2_pos_x-10'd80;
            end
            else if(10'd240<big_truck_2_pos_x-10'd80&&big_truck_2_pos_x-10'd80<10'd320)begin
                //case 2 //下一步truck1 只剩尾巴一格 (240<truck2_pos_x-80<320)
                //tail_body_bool_1=1;
                big_truck_1_pos_x<=big_truck_1_pos_x-10'd80;
                big_truck_mid_bool[0]<=0;big_truck_mid_bool[1]<=0;
                big_truck_tail_bool[0]<=1;big_truck_tail_bool[1]<=0;
                big_truck_2_pos_x<=big_truck_2_pos_x-10'd80;
            end
            else if(10'd160<big_truck_2_pos_x-10'd80&&big_truck_2_pos_x-10'd80<10'd240)begin
                //case 3 //下一步 truck1從最右邊回來 (160<truck2_pos_x-80<240)
                //big_truck_pos_x_1=10'd584;
                big_truck_1_pos_x<=10'd584;
                big_truck_mid_bool[0]<=0;big_truck_mid_bool[1]<=0;
                big_truck_tail_bool[0]<=0;big_truck_tail_bool[1]<=0;
                big_truck_2_pos_x<=big_truck_2_pos_x-10'd80;
            end
            //---------------------------------------
            else if(10'd320<big_truck_1_pos_x-10'd80&&big_truck_1_pos_x-10'd80<10'd400)begin
                //case 1 //下一步truck2要超出去 (320<truck1_pos_x-80<400)
                big_truck_2_pos_x<=big_truck_2_pos_x-10'd80;
                big_truck_mid_bool[1]<=1;big_truck_mid_bool[0]<=0;
                big_truck_tail_bool[0]<=0;big_truck_tail_bool[1]<=0;
                big_truck_1_pos_x<=big_truck_1_pos_x-10'd80;
            end
            else if(10'd240<big_truck_1_pos_x-10'd80&&big_truck_1_pos_x-10'd80<10'd320)begin
                //case 2 //下一步truck2 只剩尾巴一格 (240<truck1_pos_x-80<320)
                big_truck_2_pos_x<=big_truck_2_pos_x-10'd80;
                big_truck_mid_bool[1]<=0;big_truck_mid_bool[0]<=0;
                big_truck_tail_bool[1]<=1;big_truck_tail_bool[0]<=0;
                big_truck_1_pos_x<=big_truck_1_pos_x-10'd80;
            end
            else if(10'd160<big_truck_1_pos_x-10'd80&&big_truck_1_pos_x-10'd80<10'd240)begin
                //case 3 //下一步 truck2從最右邊回來 (160<truck1_pos_x-80<240)
                big_truck_2_pos_x<=10'd584;
                big_truck_mid_bool[1]<=0;big_truck_mid_bool[0]<=0;
                big_truck_tail_bool[0]<=0;big_truck_tail_bool[1]<=0;
                big_truck_1_pos_x<=big_truck_1_pos_x-10'd80;
            end
            else begin
                big_truck_mid_bool[1]<=0;big_truck_mid_bool[0]<=0;
                big_truck_tail_bool[0]<=0;big_truck_tail_bool[1]<=0;
                big_truck_1_pos_x<=big_truck_1_pos_x-10'd80;
                big_truck_2_pos_x<=big_truck_2_pos_x-10'd80;
            end
        end
        else begin
            big_truck_mid_bool[0]<=big_truck_mid_bool[0];
            big_truck_mid_bool[1]<=big_truck_mid_bool[1];
            big_truck_tail_bool[0]<=big_truck_tail_bool[0];
            big_truck_tail_bool[1]<=big_truck_tail_bool[1];
            big_truck_1_pos_x<=big_truck_1_pos_x;
            big_truck_2_pos_x<=big_truck_2_pos_x;
        end
    end
    
    //----------------enable控制 兩階段---Move and Win-----------
    wire clk_eye;
    always@(posedge clk_eye,negedge reset)begin
        if(!reset)begin
            enable<=4'b0001;
        end
        else if(state==Move||state==Die)begin
            if(enable==4'b0001)enable<=4'b0010;
            else if(enable==4'b0010)enable<=4'b0001;
            else enable<=4'b0000;
        end
        else begin//Win case
            if(enable==4'b0001)enable<=4'b0010;
            else if(enable==4'b0010)enable<=4'b0100;
            else if(enable==4'b0100)enable<=4'b1000;
            else if(enable==4'b1000)enable<=4'b0001;
            else enable<=4'b0000;
        end
    end

//-----------seven_seg控制-----------------
    always@(*)begin
        if(enable==4'b0001)begin
            case(total_step_digit)
                4'd0:begin segment = 8'b11111100;end 
                4'd1:begin segment = 8'b01100000;end // 1
                4'd2:begin segment = 8'b11011010;end // 2
                4'd3:begin segment = 8'b11110010;end // 3
                4'd4:begin segment = 8'b01100110;end // 4
                4'd5:begin segment = 8'b10110110;end // 5
                4'd6:begin segment = 8'b10111110;end // 6
                4'd7:begin segment = 8'b11100100;end // 7
                4'd8:begin segment = 8'b11111110;end // 8
                4'd9:begin segment = 8'b11110110;end // 9
                default segment = 8'b0;
            endcase
        end
        else if(enable==4'b0010)begin
            case(total_step_dec)
                4'd0:begin segment = 8'b11111100;end 
                4'd1:begin segment = 8'b01100000;end // 1
                4'd2:begin segment = 8'b11011010;end // 2
                4'd3:begin segment = 8'b11110010;end // 3
                4'd4:begin segment = 8'b01100110;end // 4
                4'd5:begin segment = 8'b10110110;end // 5
                4'd6:begin segment = 8'b10111110;end // 6
                4'd7:begin segment = 8'b11100100;end // 7
                4'd8:begin segment = 8'b11111110;end // 8
                4'd9:begin segment = 8'b11110110;end // 9
                default segment = 8'b0;
            endcase
        end
        else if(enable==4'b0100)begin
            segment = 8'b11110110;
        end
        else if(enable==4'b1000)begin
            segment = 8'b11110110;
        end
        else segment = 8'b0;
    end

//---------------LED控制-----------------
    reg [2:0]LED_counter;
    always@(posedge clk_1HZ,negedge reset)begin
        if(!reset)begin 
            LED_counter<=3'b0;
        end
        else if(state==Die&&LED_counter==3'b0)begin 
            LED_counter<=3'd1;//啟動條件
            // LED<=16'b1111_0000_0000_1111;
        end
        else if(state==Die&&LED_counter>3'b0&&LED_counter<3'd7)begin 
            LED_counter<=LED_counter+3'd1;//往下加
            // LED<=16'b1111_0000_0000_0000;
        end
        else if(state==Die&&LED_counter==3'd7)begin 
            // LED<=16'b0000_1111_0000_0000;
            LED_counter<=3'd0;
        end
        else begin 
            LED_counter<=3'b0;
            // LED<=16'b0000_0000_0000_1111;
        end
    end

    always@(*)begin
        if(state!=Die)LED=16'b0;
        else begin
            case(LED_counter)
            3'd0:LED=16'b0000_0001_1000_0000;
            3'd1:LED=16'b0000_0010_0100_0000;
            3'd2:LED=16'b0000_0100_0010_0000;
            3'd3:LED=16'b0000_1000_0001_0000;
            3'd4:LED=16'b0001_0000_0000_1000;
            3'd5:LED=16'b0010_0000_0000_0100;
            3'd6:LED=16'b0100_0000_0000_0010;
            3'd7:LED=16'b1000_0000_0000_0001;
            endcase
        end
    end

    // 讓car動 1 step/1 s
    always@(posedge clk_1HZ,negedge reset)begin
        if(!reset)begin
            car_pos_y<=10'd328;   //64*64
            car_1_pos_x<=10'd8;        
            car_2_pos_x<=10'd248;
            car_3_pos_x<=10'd488;
        end
        else if(state==Move)begin
            //超出去的就不讓它顯示 例如第三個超出去
            if(car_3_pos_x+10'd80>10'd560&&car_1_pos_x+10'd80>10'd240&&car_1_pos_x+10'd80<10'd320)begin //car3回來了
                car_3_pos_x<=10'd8;car_1_pos_x<=car_1_pos_x+10'd80;car_2_pos_x<=car_2_pos_x+10'd80;
                car_pos_y<=10'd328;
            end
            else if(car_3_pos_x+10'd80>10'd560&&car_1_pos_x+10'd80<10'd240)begin //car3超出去
                car_3_pos_x<=car_3_pos_x+10'd80;car_1_pos_x<=car_1_pos_x+10'd80;car_2_pos_x<=car_2_pos_x+10'd80;
                car_pos_y<=10'd328;
            end

            //---------------------------------
            else if(car_2_pos_x+10'd80>10'd560&&car_3_pos_x+10'd80>10'd240&&car_3_pos_x+10'd80<10'd320)begin 
                car_2_pos_x<=10'd8;car_1_pos_x<=car_1_pos_x+10'd80;car_3_pos_x<=car_3_pos_x+10'd80;
                car_pos_y<=10'd328;
            end
            else if(car_2_pos_x+10'd80>10'd560&&car_3_pos_x+10'd80<10'd240)begin //car2超出去
                car_2_pos_x<=car_2_pos_x+10'd80;car_1_pos_x<=car_1_pos_x+10'd80;car_3_pos_x<=car_3_pos_x+10'd80;
                car_pos_y<=10'd328;
            end
            //-----------------------------------------------------
            else if(car_1_pos_x+10'd80>10'd560&&car_2_pos_x+10'd80>10'd240&&car_2_pos_x+10'd80<10'd320)begin//car1回來
                car_1_pos_x<=10'd8;car_2_pos_x<=car_2_pos_x+10'd80;car_3_pos_x<=car_3_pos_x+10'd80;
                car_pos_y<=10'd328;
            end
            else if(car_1_pos_x+10'd80>10'd560&&car_2_pos_x+10'd80<10'd240)begin//car1超出去
                car_1_pos_x<=car_1_pos_x+10'd80;car_2_pos_x<=car_2_pos_x+10'd80;car_3_pos_x<=car_3_pos_x+10'd80;
                car_pos_y<=10'd328;
            end
            else begin
                car_1_pos_x<=car_1_pos_x+10'd80;car_2_pos_x<=car_2_pos_x+10'd80;car_3_pos_x<=car_3_pos_x+10'd80;
                car_pos_y<=10'd328;
            end
        end
        else begin
            car_1_pos_x<=car_1_pos_x;car_2_pos_x<=car_2_pos_x;car_3_pos_x<=car_3_pos_x;
            car_pos_y<=10'd328;
        end
    end
    
    //---------讓truck動-------------
    // 讓car動 1 step/1 s
    always@(posedge clk_05HZ,negedge reset)begin
        if(!reset)begin
            truck_pos_y<=10'd248;
            truck_1_pos_x<=10'd16;
            truck_2_pos_x<=10'd256;
            truck_3_pos_x<=10'd496;
            truck_head_bool<=3'd0;
        end
        else if(state==Move)begin
            if(truck_3_pos_x+10'd80>10'd560&&truck_1_pos_x+10'd80>10'd240&&truck_1_pos_x+10'd80<10'd320)begin //car3整台回來了
                truck_3_pos_x<=10'd8;truck_1_pos_x<=truck_1_pos_x+10'd80;truck_2_pos_x<=truck_2_pos_x+10'd80;
                truck_pos_y<=truck_pos_y;
                truck_head_bool[2]<=0;truck_head_bool[1]<=0;truck_head_bool[0]<=0;//特例結束
            end
            else if(truck_3_pos_x+10'd80>10'd560&&truck_1_pos_x+10'd80<10'd240)begin //car3回來半台
                if(truck_1_pos_x+10'd80>10'd160)begin
                    truck_3_pos_x<=truck_3_pos_x+10'd80;//1 2還是照算
                    truck_1_pos_x<=truck_1_pos_x+10'd80;truck_2_pos_x<=truck_2_pos_x+10'd80;
                    truck_pos_y<=truck_pos_y;
                    //特例處理
                    truck_head_bool[2]<=1;truck_head_bool[1]<=0;truck_head_bool[0]<=0;
                end
                else begin
                    truck_1_pos_x<=truck_1_pos_x+10'd80;truck_2_pos_x<=truck_2_pos_x+10'd80;truck_3_pos_x<=truck_3_pos_x+10'd80;
                    truck_pos_y<=truck_pos_y;
                end
            end

            //---------------------------------
            else if(truck_2_pos_x+10'd80>10'd560&&truck_3_pos_x+10'd80>10'd240&&truck_3_pos_x+10'd80<10'd320)begin 
                truck_2_pos_x<=10'd8;truck_1_pos_x<=truck_1_pos_x+10'd80;truck_3_pos_x<=truck_3_pos_x+10'd80;
                truck_pos_y<=truck_pos_y;
                truck_head_bool[2]<=0;truck_head_bool[1]<=0;truck_head_bool[0]<=0;
            end
            else if(truck_2_pos_x+10'd80>10'd560&&truck_3_pos_x+10'd80<10'd240)begin //truck2超出去
                if(truck_3_pos_x+10'd80>10'd160)begin
                    truck_2_pos_x<=truck_2_pos_x+10'd80;truck_1_pos_x<=truck_1_pos_x+10'd80;truck_3_pos_x<=truck_3_pos_x+10'd80;
                    truck_pos_y<=truck_pos_y;
                    truck_head_bool[2]<=0;truck_head_bool[1]<=1;truck_head_bool[0]<=0;
                end
                else begin
                    truck_1_pos_x<=truck_1_pos_x+10'd80;truck_2_pos_x<=truck_2_pos_x+10'd80;truck_3_pos_x<=truck_3_pos_x+10'd80;
                    truck_pos_y<=truck_pos_y;
                end
            end

            //-----------------------------------------------------
            else if(truck_1_pos_x+10'd80>10'd560&&truck_2_pos_x+10'd80>10'd240&&truck_2_pos_x+10'd80<10'd320)begin//car1回來
                truck_1_pos_x<=10'd8;truck_2_pos_x<=truck_2_pos_x+10'd80;truck_3_pos_x<=truck_3_pos_x+10'd80;
                truck_pos_y<=truck_pos_y;
                truck_head_bool[2]<=0;truck_head_bool[1]<=0;truck_head_bool[0]<=0;
            end
            else if(truck_1_pos_x+10'd80>10'd560&&truck_2_pos_x+10'd80<10'd240)begin//car1超出去
                if(truck_2_pos_x+10'd80>=10'd160)begin
                    truck_1_pos_x<=truck_1_pos_x+10'd80;truck_2_pos_x<=truck_2_pos_x+10'd80;truck_3_pos_x<=truck_3_pos_x+10'd80;
                    truck_pos_y<=truck_pos_y;
                    truck_head_bool[2]<=0;truck_head_bool[1]<=0;truck_head_bool[0]<=1;
                end
                else begin
                    truck_1_pos_x<=truck_1_pos_x+10'd80;truck_2_pos_x<=truck_2_pos_x+10'd80;truck_3_pos_x<=truck_3_pos_x+10'd80;
                    truck_pos_y<=truck_pos_y;
                end
            end
            else begin
                truck_1_pos_x<=truck_1_pos_x+10'd80;truck_2_pos_x<=truck_2_pos_x+10'd80;truck_3_pos_x<=truck_3_pos_x+10'd80;
                truck_pos_y<=truck_pos_y;
            end
        end
        else begin
            truck_1_pos_x<=truck_1_pos_x;truck_2_pos_x<=truck_2_pos_x;truck_3_pos_x<=truck_3_pos_x;
            truck_pos_y<=truck_pos_y;
        end
    end

    //除頻器
    reg [27:0]count_27;
    always@(posedge clk,negedge reset)begin
        if(!reset)count_27<=27'd0;
        else count_27<=count_27+1'd1;
    end
    assign clk_1HZ=count_27[26];
    assign clk_05HZ=count_27[27];
    assign clk_debounce=count_27[12];
    assign clk_eye=count_27[15];
    assign {vga_r,vga_g,vga_b}=vga_data;

endmodule 

//syngeneration
module SyncGeneration(pclk, reset, hSync, vSync, dataValid, hDataCnt, vDataCnt);
input pclk;
input reset;
output hSync;
output vSync;
output dataValid;
output [9:0] hDataCnt;
output [9:0] vDataCnt;

parameter H_SP_END = 96;
parameter H_BP_END = 144;
parameter H_FP_START = 785;
parameter H_TOTAL = 800;

parameter V_SP_END = 2;
parameter V_BP_END = 35;
parameter V_FP_START = 516;
parameter V_TOTAL= 525;
reg [9:0] x_cnt, y_cnt;
wire h_valid, y_valid;

always @(posedge pclk or negedge reset) begin
    if (!reset)
        x_cnt <= 10'd1;
    else begin
        if (x_cnt == H_TOTAL) // horizontal 
            x_cnt <= 10'd1; // retracing
        else
            x_cnt <= x_cnt + 1'b1;
    end
end
always @(posedge pclk or negedge reset) begin
    if (!reset)
        y_cnt <= 10'd1;
    else begin
        if (y_cnt == V_TOTAL & x_cnt == H_TOTAL)
            y_cnt <= 1; // vertical retracing
        else if (x_cnt == H_TOTAL)
            y_cnt <= y_cnt + 1;
        else 
            y_cnt<=y_cnt;
    end
end

assign hSync = ((x_cnt > H_SP_END)) ? 1'b1 : 1'b0;
assign vSync = ((y_cnt > V_SP_END)) ? 1'b1 : 1'b0;
// Check P7 for horizontal timing
assign h_valid = ((x_cnt > H_BP_END) & (x_cnt < H_FP_START)) ? 1'b1 : 1'b0;
// Check P9 for vertical timing
assign v_valid = ((y_cnt > V_BP_END) & (y_cnt < V_FP_START)) ? 1'b1 : 1'b0;
assign dataValid = ((h_valid == 1'b1) & (v_valid == 1'b1)) ? 1'b1 : 1'b0;
// hDataCnt from 1 if h_valid==1
assign hDataCnt = ((h_valid == 1'b1)) ? x_cnt - H_BP_END : 10'b0;
// vDataCnt from 1 if v_valid==1
assign vDataCnt = ((v_valid == 1'b1)) ? y_cnt - V_BP_END : 10'b0;
endmodule

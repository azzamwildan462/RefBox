
/**
* Based on https://msl.robocup.org/wp-content/uploads/2024/05/Rulebook_MSL2024_v25.1.pdf
*
* Requirements: 
* - All teams must have a standard unit for pose 
* - All teams must have a standard localization of their robots 
* - All teams must have a standard world coordinate system 
* - All teams must have a standard rule for numberings their robots 
*/

static class AutoRef {
   /**
   * FIELDS LEGENDS KRI!!
   */
   private static final float CYAN_PENALTY_X_MIN = 1.5;
   private static final float CYAN_PENALTY_Y_MIN = 0.0;
   private static final float CYAN_PENALTY_X_MAX = 6.5;
   private static final float CYAN_PENALTY_Y_MAX = 1.8;

   private static final float MAGENTA_PENALTY_X_MIN = 1.5;
   private static final float MAGENTA_PENALTY_Y_MIN = 10.2;
   private static final float MAGENTA_PENALTY_X_MAX = 6.5;
   private static final float MAGENTA_PENALTY_Y_MAX = 13;

   // /**
   // * FIELDS LEGENDS ROBOCUP!!
   // */
   // private static final float CYAN_PENALTY_X_MIN = 3.5;
   // private static final float CYAN_PENALTY_Y_MIN = 0.0;
   // private static final float CYAN_PENALTY_X_MAX = 10.5;
   // private static final float CYAN_PENALTY_Y_MAX = 2.25;

   // private static final float MAGENTA_PENALTY_X_MIN = 3.5;
   // private static final float MAGENTA_PENALTY_Y_MIN = 17.75;
   // private static final float MAGENTA_PENALTY_X_MAX = 10.5;
   // private static final float MAGENTA_PENALTY_Y_MAX = 22;

   /**
   * SOME MISC VAR
   */
   private static final float ROBOT_RADIUS = 0.26;

   private static long my_millis = 0;

   /**
   * FSM
   */
   private static int fsm_illegal_attack_a = 0; 
   private static int fsm_illegal_defend_a = 0; 
   private static int fsm_illegal_attack_b = 0; 
   private static int fsm_illegal_defend_b = 0; 
   private static int fsm_max_dribbling_a = 0;
   private static int fsm_max_dribbling_b = 0;

   private static int fsm_illegal_attack_used = 0;
   private static int fsm_illegal_defend_used = 0;
   private static int fsm_max_dribbling_used = 0;

   private static float pos_x_start_backward_motion = 0;
   private static float pos_y_start_backward_motion = 0;
   private static float pos_x_start_dribbling = 0;
   private static float pos_y_start_dribbling = 0;

   /**
   * Some utils variables
   */
   private static int n_robot_suspected_bin = 0;
   private static long time_start_suspect_illegal_attack_a = 0;
   private static long time_start_suspect_illegal_attack_b = 0;
   private static long time_start_suspect_illegal_defend_a = 0;
   private static long time_start_suspect_illegal_defend_b = 0;

   private static long time_start_illegal_attack = 0; 
   private static long time_start_illegal_defend = 0;

   private static long time_start_violation = 0;
   private static int team_that_violated = 0;
   private static int prev_team_that_violated = 0;

   private static float pos_counter_x_backward = 0; 
   private static float pos_counter_y_backward = 0;

   /**
   * Update the max distance for dribbling motion
   */
   private static void update_max_dribbling(Team current_team){
      fsm_max_dribbling_used = current_team.isLeft ? fsm_max_dribbling_a : fsm_max_dribbling_b;

      if(current_team.n_robot_has_ball > 0){
         cprintf("%.2f %.2f || %.2f %.2f\n",pos_x_start_backward_motion, pos_y_start_backward_motion,pos_counter_x_backward,pos_counter_y_backward);
      }

      // Always reset state machine to 0, if game stopped
      if(StateMachine.GetCurrentGameButton() == ButtonsEnum.BTN_STOP || 
      StateMachine.GetCurrentGameButton() == ButtonsEnum.BTN_ILLEGAL){
         fsm_max_dribbling_used = 0;
      }

      switch (fsm_max_dribbling_used){
         case 0: 
            if(current_team.n_robot_has_ball > 0){
               fsm_max_dribbling_used = 1;
            }
         break;

         case 1: 
            if(current_team.n_robot_has_ball == 0){
               fsm_max_dribbling_used = 0;
               break;
            }

            pos_x_start_dribbling = current_team.robot_pose[current_team.n_robot_has_ball - 1][0];
            pos_y_start_dribbling = current_team.robot_pose[current_team.n_robot_has_ball - 1][1];
            pos_x_start_backward_motion = current_team.robot_pose[current_team.n_robot_has_ball - 1][0];
            pos_y_start_backward_motion = current_team.robot_pose[current_team.n_robot_has_ball - 1][1];
            fsm_max_dribbling_used = 2;

            pos_counter_x_backward = pos_x_start_backward_motion;
            pos_counter_y_backward = pos_y_start_backward_motion;
            

         break;

         case 2: 
            if(current_team.n_robot_has_ball == 0){
               fsm_max_dribbling_used = 0;
               break;
            }

            // If robot start backward motion
            if(Math.abs(current_team.robot_vel_local[current_team.n_robot_has_ball - 1][1]) > 
            Math.abs(current_team.robot_vel_local[current_team.n_robot_has_ball - 1][0]) * 0.002){
               if(current_team.robot_vel_local[current_team.n_robot_has_ball - 1][1] < -0.0001){
                  if(pythagoras(pos_x_start_backward_motion, pos_y_start_backward_motion, current_team.robot_pose[current_team.n_robot_has_ball - 1][0], current_team.robot_pose[current_team.n_robot_has_ball - 1][1]) >= 2){
                     // team_that_violated = current_team.isLeft ? 1 : 2;
                     // StateMachine.Update(ButtonsEnum.BTN_STOP, false);
                     // send_event_v2(COMM_STOP, COMM_STOP, null,-1);
                     // time_start_violation = my_millis;
                     // Log.screenlog("Ballhandling Foul on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
                     // fsm_max_dribbling_used = 0;

                     // log2stdout("HELLOOOOOOO");

                     pos_counter_x_backward += (float)(current_team.robot_vel_local[current_team.n_robot_has_ball - 1][0] / 40);
                     pos_counter_y_backward += (float)(current_team.robot_vel_local[current_team.n_robot_has_ball - 1][1] / 40);
                  }
               }
               else {
                  // pos_x_start_backward_motion = current_team.robot_pose[current_team.n_robot_has_ball - 1][0];
                  // pos_y_start_backward_motion = current_team.robot_pose[current_team.n_robot_has_ball - 1][1];
                  if(pythagoras(pos_x_start_dribbling, pos_y_start_dribbling, current_team.robot_pose[current_team.n_robot_has_ball - 1][0], current_team.robot_pose[current_team.n_robot_has_ball - 1][1]) >= 3){
                     team_that_violated = current_team.isLeft ? 1 : 2;
                     StateMachine.Update(ButtonsEnum.BTN_STOP, false);
                     send_event_v2(COMM_STOP, COMM_STOP, null,-1);
                     time_start_violation = my_millis;
                     Log.screenlog("Ballhandling Foul on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
                     fsm_max_dribbling_used = 0;
                  }
               }
            }else {
               // pos_x_start_backward_motion = current_team.robot_pose[current_team.n_robot_has_ball - 1][0];
               // pos_y_start_backward_motion = current_team.robot_pose[current_team.n_robot_has_ball - 1][1];
               if(pythagoras(pos_x_start_dribbling, pos_y_start_dribbling, current_team.robot_pose[current_team.n_robot_has_ball - 1][0], current_team.robot_pose[current_team.n_robot_has_ball - 1][1]) >= 3){
                  team_that_violated = current_team.isLeft ? 1 : 2;
                  StateMachine.Update(ButtonsEnum.BTN_STOP, false);
                  send_event_v2(COMM_STOP, COMM_STOP, null,-1);
                  time_start_violation = my_millis;
                  Log.screenlog("Ballhandling Foul on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
                  fsm_max_dribbling_used = 0;
               }
            }

            // if(pythagoras(pos_x_start_dribbling, pos_y_start_dribbling, current_team.robot_pose[current_team.n_robot_has_ball - 1][0], current_team.robot_pose[current_team.n_robot_has_ball - 1][1]) >= 3){
            //    team_that_violated = current_team.isLeft ? 1 : 2;
            //    StateMachine.Update(ButtonsEnum.BTN_STOP, false);
            //    send_event_v2(COMM_STOP, COMM_STOP, null,-1);
            //    time_start_violation = my_millis;
            //    Log.screenlog("Ballhandling Foul on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
            //    fsm_max_dribbling_used = 0;
            // }

         break;
      }

      if(current_team.isLeft){
         fsm_max_dribbling_a = fsm_max_dribbling_used;
      }
      else{
         fsm_max_dribbling_b = fsm_max_dribbling_used;
      }
   };

   private static void update_illegal_attack(Team current_team){
      fsm_illegal_attack_used = current_team.isLeft ? fsm_illegal_attack_a : fsm_illegal_attack_b;

      int counter_suspected_robot = 0;
      int n_robot_suspected = 0;

      // Always reset state machine to 0, if game stopped
      if(StateMachine.GetCurrentGameButton() == ButtonsEnum.BTN_STOP || 
      StateMachine.GetCurrentGameButton() == ButtonsEnum.BTN_ILLEGAL){
         fsm_illegal_attack_used = 0;
      }

      switch (fsm_illegal_attack_used) {
         case 0: 

         counter_suspected_robot = 0;
         for(int i = 0; i < 5; i++){
            
            if(current_team.robot_pose[i][0] >( current_team.isLeft ? MAGENTA_PENALTY_X_MIN : CYAN_PENALTY_X_MIN) && 
            current_team.robot_pose[i][0] < (current_team.isLeft ? MAGENTA_PENALTY_X_MAX : CYAN_PENALTY_X_MAX) && 
            current_team.robot_pose[i][1] > (current_team.isLeft ? MAGENTA_PENALTY_Y_MIN : CYAN_PENALTY_Y_MIN) && 
            current_team.robot_pose[i][1] < (current_team.isLeft ? MAGENTA_PENALTY_Y_MAX : CYAN_PENALTY_Y_MAX)){
               set_suspect_robot_num(i + (current_team.isLeft ? 0 : 5));
               counter_suspected_robot++;
            }
            else { 
               n_robot_suspected_bin &= ~(1 << (i + (current_team.isLeft ? 0 : 5)));
            }
         }

         // If more than one robot suspected
         if(counter_suspected_robot > 1){
            team_that_violated = current_team.isLeft ? 1 : 2;
            StateMachine.Update(ButtonsEnum.BTN_STOP, false);
            send_event_v2(COMM_STOP, COMM_STOP, null,-1);
            time_start_violation = my_millis;
            Log.screenlog("Illegal Attack on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
         }
         else if(counter_suspected_robot == 1){
            time_start_illegal_attack = my_millis;
            fsm_illegal_attack_used = 1;
         }
         break;

         case 1: 
         n_robot_suspected = five_bit_to_num((n_robot_suspected_bin & (current_team.isLeft ? 0b11111 : 0b1111100000)) >> (current_team.isLeft ? 0 : 5));

         System.out.println("N ROBOT SUSPECTED: " + n_robot_suspected);

         // Check other robot
         counter_suspected_robot = 1;
         for(int i = 0; i < 5; i++){
            if(i == n_robot_suspected){
               continue;
            }

            if(current_team.robot_pose[i][0] >( current_team.isLeft ? MAGENTA_PENALTY_X_MIN : CYAN_PENALTY_X_MIN) && 
            current_team.robot_pose[i][0] < (current_team.isLeft ? MAGENTA_PENALTY_X_MAX : CYAN_PENALTY_X_MAX) && 
            current_team.robot_pose[i][1] > (current_team.isLeft ? MAGENTA_PENALTY_Y_MIN : CYAN_PENALTY_Y_MIN) && 
            current_team.robot_pose[i][1] < (current_team.isLeft ? MAGENTA_PENALTY_Y_MAX : CYAN_PENALTY_Y_MAX)){
               counter_suspected_robot++;
            }
         }

         if(counter_suspected_robot > 1){
            fsm_illegal_attack_used = 0;
            team_that_violated = current_team.isLeft ? 1 : 2;
            StateMachine.Update(ButtonsEnum.BTN_STOP, false);
            send_event_v2(COMM_STOP, COMM_STOP, null,-1);
            time_start_violation = my_millis;
            Log.screenlog("Illegal Attack on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
            break;
         }

         if(!(current_team.robot_pose[n_robot_suspected][0] >( current_team.isLeft ? MAGENTA_PENALTY_X_MIN : CYAN_PENALTY_X_MIN) && 
            current_team.robot_pose[n_robot_suspected][0] < (current_team.isLeft ? MAGENTA_PENALTY_X_MAX : CYAN_PENALTY_X_MAX) && 
            current_team.robot_pose[n_robot_suspected][1] > (current_team.isLeft ? MAGENTA_PENALTY_Y_MIN : CYAN_PENALTY_Y_MIN) && 
            current_team.robot_pose[n_robot_suspected][1] < (current_team.isLeft ? MAGENTA_PENALTY_Y_MAX : CYAN_PENALTY_Y_MAX))){
            fsm_illegal_attack_used = 0;
            break;
         }


         if(my_millis - time_start_illegal_attack > 10000){
            fsm_illegal_attack_used = 0;
            team_that_violated = current_team.isLeft ? 1 : 2;
            StateMachine.Update(ButtonsEnum.BTN_STOP, false);
            send_event_v2(COMM_STOP, COMM_STOP, null,-1);
            time_start_violation = my_millis;
            Log.screenlog("Illegal Attack on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
            break;
         }

         break;
      }


      if(current_team.isLeft){
         fsm_illegal_attack_a = fsm_illegal_attack_used;
      }
      else{
         fsm_illegal_attack_b = fsm_illegal_attack_used;
      }

   };

   private static void update_illegal_defend(Team current_team){
      fsm_illegal_defend_used = current_team.isLeft ? fsm_illegal_defend_a : fsm_illegal_defend_b;

      int counter_suspected_robot = 0;
      int n_robot_suspected = 0;

      // Always reset state machine to 0, if game stopped
      if(StateMachine.GetCurrentGameButton() == ButtonsEnum.BTN_STOP || 
      StateMachine.GetCurrentGameButton() == ButtonsEnum.BTN_ILLEGAL){
         fsm_illegal_defend_used = 0;
      }

      switch (fsm_illegal_defend_used) {
         case 0: 

         counter_suspected_robot = 0;
         for(int i = 0; i < 5; i++){
            
            if(current_team.robot_pose[i][0] >(!current_team.isLeft ? MAGENTA_PENALTY_X_MIN : CYAN_PENALTY_X_MIN) && 
            current_team.robot_pose[i][0] < (!current_team.isLeft ? MAGENTA_PENALTY_X_MAX : CYAN_PENALTY_X_MAX) && 
            current_team.robot_pose[i][1] > (!current_team.isLeft ? MAGENTA_PENALTY_Y_MIN : CYAN_PENALTY_Y_MIN) && 
            current_team.robot_pose[i][1] < (!current_team.isLeft ? MAGENTA_PENALTY_Y_MAX : CYAN_PENALTY_Y_MAX)){
               set_suspect_robot_num(i + (current_team.isLeft ? 10 : 15));
               counter_suspected_robot++;
            }
            else { 
               n_robot_suspected_bin &= ~(1 << (i + (current_team.isLeft ? 10 : 15)));
            }
         }

         // If more than one robot suspected
         if(counter_suspected_robot > 1){
            team_that_violated = current_team.isLeft ? 1 : 2;
            StateMachine.Update(ButtonsEnum.BTN_STOP, false);
            send_event_v2(COMM_STOP, COMM_STOP, null,-1);
            time_start_violation = my_millis;
            Log.screenlog("Illegal Defend on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
         }
         else if(counter_suspected_robot == 1){
            time_start_illegal_defend = my_millis;
            fsm_illegal_defend_used = 1;
         }
         break;

         case 1: 
         n_robot_suspected = five_bit_to_num((n_robot_suspected_bin & (current_team.isLeft ? 0b111110000000000 : 0b11111000000000000000)) >> (current_team.isLeft ? 10 : 15));

         // Check other robot
         counter_suspected_robot = 1;
         for(int i = 0; i < 5; i++){
            if(i == n_robot_suspected){
               continue;
            }

            if(current_team.robot_pose[i][0] >(!current_team.isLeft ? MAGENTA_PENALTY_X_MIN : CYAN_PENALTY_X_MIN) && 
            current_team.robot_pose[i][0] < (!current_team.isLeft ? MAGENTA_PENALTY_X_MAX : CYAN_PENALTY_X_MAX) && 
            current_team.robot_pose[i][1] > (!current_team.isLeft ? MAGENTA_PENALTY_Y_MIN : CYAN_PENALTY_Y_MIN) && 
            current_team.robot_pose[i][1] < (!current_team.isLeft ? MAGENTA_PENALTY_Y_MAX : CYAN_PENALTY_Y_MAX)){
               counter_suspected_robot++;
            }
         }

         if(counter_suspected_robot > 1){
            fsm_illegal_defend_used = 0;
            team_that_violated = current_team.isLeft ? 1 : 2;
            StateMachine.Update(ButtonsEnum.BTN_STOP, false);
            send_event_v2(COMM_STOP, COMM_STOP, null,-1);
            time_start_violation = my_millis;
            Log.screenlog("Illegal Defend on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
            break;
         }

         if(!(current_team.robot_pose[n_robot_suspected][0] >(!current_team.isLeft ? MAGENTA_PENALTY_X_MIN : CYAN_PENALTY_X_MIN) && 
            current_team.robot_pose[n_robot_suspected][0] < (!current_team.isLeft ? MAGENTA_PENALTY_X_MAX : CYAN_PENALTY_X_MAX) && 
            current_team.robot_pose[n_robot_suspected][1] > (!current_team.isLeft ? MAGENTA_PENALTY_Y_MIN : CYAN_PENALTY_Y_MIN) && 
            current_team.robot_pose[n_robot_suspected][1] < (!current_team.isLeft ? MAGENTA_PENALTY_Y_MAX : CYAN_PENALTY_Y_MAX))){
            fsm_illegal_defend_used = 0;
            break;
         }


         if(my_millis - time_start_illegal_defend > 10000){
            fsm_illegal_defend_used = 0;
            team_that_violated = current_team.isLeft ? 1 : 2;
            StateMachine.Update(ButtonsEnum.BTN_STOP, false);
            send_event_v2(COMM_STOP, COMM_STOP, null,-1);
            time_start_violation = my_millis;
            Log.screenlog("Illegal Defend on " + (current_team.isLeft ? "CYAN" : "MAGENTA"));
            break;
         }

         break;
      }


      if(current_team.isLeft){
         fsm_illegal_defend_a = fsm_illegal_defend_used;
      }
      else{
         fsm_illegal_defend_b = fsm_illegal_defend_used;
      }
   };

   private static void update(){
      my_millis = System.currentTimeMillis();

      update_max_dribbling(teamA);
      update_max_dribbling(teamB);

      update_illegal_attack(teamA);
      update_illegal_attack(teamB);

      update_illegal_defend(teamA);
      update_illegal_defend(teamB);

      // System.out.println(StateMachine.setpiece_button);

      // if(team_that_violated > 0){
      //    if(my_millis - time_start_violation > 5000){
      //       if(team_that_violated == 1){
      //          StateMachine.Update(ButtonsEnum.BTN_R_FREEKICK, false);
      //       }else{
      //          StateMachine.Update(ButtonsEnum.BTN_L_FREEKICK, false);
      //       }
      //       team_that_violated = 0;
      //    }

      //    // Jika sekarnag sudah tidak stop 
      //    if(StateMachine.gsCurrent == GameStateEnum.GS_GAMEON_H1 || 
      //       StateMachine.gsCurrent == GameStateEnum.GS_GAMEON_H2 ||
      //       StateMachine.gsCurrent == GameStateEnum.GS_GAMEON_H3 ||
      //       StateMachine.gsCurrent == GameStateEnum.GS_GAMEON_H4){
      //       team_that_violated = 0;
      //    }
      // }
   };


   private static void set_suspect_robot_num(int num){
      // Safety
      if(num == 0)
      {
         return;
      }

      n_robot_suspected_bin &= ~(1 << (num));
      n_robot_suspected_bin |= (1 << (num)); 

      // System.out.println("SET SUS ON: " + (num +1) + " -> " + n_robot_suspected_bin);
   };

   private static int five_bit_to_num(int n){
      int num = 0;
      for(int i = 0; i < 5; i++){
         if((n & (1 << i)) != 0){
            num = i;
            break;
         }
      }

      return num;
   };

   private static double pythagoras(float x1, float y1, float x2, float y2){
      return Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
   };

   private static void log2stdout(String str){
      System.out.println(str);
      return;
   }

   private static void cprintf(String format, Object... args) {
      System.out.printf(format, args);
   }

};


(** Heuristics are supposed to restrict the universe by choosing configurations that are relevant for simulation.
    They allow to focus on execution of models, and become handy to test your specifications.
*)

(* Heuristic 1. In a universe, the heuristic keeps snapshots with the minimal number of floating ticks.
   We need to force the occurence of events as soon as possible. *)
fun heuristic_minimize_floating_ticks (cfs : TESL_ARS_conf list) : TESL_ARS_conf list =
  let
    fun nb_floating (frun: TESL_formula) : int =
      List.length (List.filter (fn Sporadic _ => true | WhenTickingOn _ => true | _ => false) frun)
    val min_spor : int =
      List.foldl (fn ((_, _, frun, _), n) => Int.min(n, nb_floating frun)) MAXINT cfs
  in List.filter
	  (fn (_, _, frun, _) => (nb_floating frun) <= min_spor)
	  cfs
  end

(* Heuristic 2. Rejects runs containing empty instants. Something always have to happen at any step. *)
fun heuristic_no_empty_instants (cfs : TESL_ARS_conf list) : TESL_ARS_conf list =
  let fun has_at_least_one_event (G: system) (step : int) =
    List.exists (fn Ticks _ => true | _ => false) (haa_constrs_at_step G step)
  in List.filter
    (fn (G, n, _, _) =>
      List.all (fn n => has_at_least_one_event G n) (range n)
    ) cfs
  end

(* Heuristic 3. Maximize reactiveness of clocks *)
fun heuristic_maximize_reactiveness (cfs : TESL_ARS_conf list) : TESL_ARS_conf list =
  let
    val cfs = List.map (fn (G, n, frun, finst) => (reduce G, n, frun, finst)) cfs
    fun nb_ticks (G: system) : int =
      List.length (List.filter (fn Ticks _ => true | _ => false) G)
    val max_ticks : int =
      List.foldl (fn ((G, _, _, _), n) => Int.max(n, nb_ticks G)) MININT cfs
  in List.filter
	  (fn (G, _, _, _) => max_ticks <= (nb_ticks G))
	  cfs
  end

(* Heuristic 4. Minimizes the number of affine constraints containing variables. *)
fun heuristic_minimize_unsolved_affine (cfs : TESL_ARS_conf list) : TESL_ARS_conf list =
  let
    val cfs = List.map (fn (G, n, frun, finst) => (reduce G, n, frun, finst)) cfs
    fun nb_unsolved_affine (G: system) : int =
      List.length (List.filter (fn Affine (x1, _, x2, _) =>
					(case (x1, x2) of
					     (Unit, Unit)   => false
					   | (Int _, Int _) => false
					   | (Rat _, Rat _) => false
					   | _  => true
					)
				   | _ => false) G)
    val min_unsolved_affine : int =
      List.foldl (fn ((G, _, _, _), n) => Int.min(n, nb_unsolved_affine G)) MAXINT cfs
  in List.filter
	  (fn (G, _, _, _) => (nb_unsolved_affine G) <= min_unsolved_affine)
	  cfs
  end

(* Heuristic 5. Minimizes the number of affine constraints containing variables. *)
fun heuristic_minimize_ticks (cfs : TESL_ARS_conf list) : TESL_ARS_conf list =
  let
    val cfs = List.map (fn (G, n, frun, finst) => (reduce G, n, frun, finst)) cfs
    fun nb_ticks (G: system) : int =
      List.length (List.filter (fn Ticks _ => true | _ => false) G)
    val min_ticks : int =
      List.foldl (fn ((G, _, _, _), n) => Int.min(n, nb_ticks G)) MAXINT cfs
  in List.filter
	  (fn (G, _, _, _) => (nb_ticks G) <= min_ticks)
	  cfs
  end

(* Heuristic 5. Minimizes the number of affine constraints containing variables. *)
fun heuristic_minimize_ticks (cfs : TESL_ARS_conf list) : TESL_ARS_conf list =
  let
    val cfs = List.map (fn (G, n, frun, finst) => (reduce G, n, frun, finst)) cfs
    fun nb_ticks (G: system) : int =
      List.length (List.filter (fn Ticks _ => true | _ => false) G)
    val min_ticks : int =
      List.foldl (fn ((G, _, _, _), n) => Int.min(n, nb_ticks G)) MAXINT cfs
  in List.filter
	  (fn (G, _, _, _) => (nb_ticks G) <= min_ticks)
	  cfs
  end

(*
fun intlist_lexleq (l1, l2) = case (l1, l2) of
    ([], _) => true
  | (x1 :: l1', x2 :: l2') => x1 <= x2 andalso (intlist_lexleq (l1', l2'))
*)

(* Heuristic 6. Maximize time progress. *)
(*
fun heuristic_maximize_time_progress (cfs : TESL_ARS_conf list) : TESL_ARS_conf list =
  let
    val clock_decl = List.foldl (fn ((G, _, frun, _), l) => uniq (l @ (clocks_of_system G) @ (clocks_of_tesl_formula frun))) [] cfs
    (* The score of a configuration increases the more time elapse *)
    fun whattime (G: system): tag option list =
      List.map (fn c => 
		     case List.find (fn Timestamp (c', step, _) => c = c' andalso List.all (fn Timestamp (c'', step', _) => c' = c'' andalso step >= step' | _ => true) G | _ => false) G of
			  NONE                         => NONE
			| SOME (Timestamp (c, n, tag)) => SOME tag
			| _ => raise UnexpectedMatch
		 ) clock_decl
    val MINSCORE = List.map (fn _ => NONE) clock_decl
    fun leq_score (l1, l2) = case (l1, l2) of
				     ([], []) => true
				   | (tago1 :: l1', tago2 :: l2') => (case (tago1, tago2) of
										  (NONE, NONE) => true
							 			| (SOME tag, NONE) => false
										| (NONE, SOME tag) => true
										| (SOME tag1, SOME tag2) => ::<= (tag1, tag2) andalso leq_score (l1', l2')
									   )
				    | _ => raise UnexpectedMatch
    fun max_score (l1, l2) = if leq_score (l1, l2) then l2 else l1
    val max_time_progress: tag option list =
	 List.foldl (fn ((G, _, _, _), n) => max_score (n, whattime G)) MINSCORE cfs
  in
    List.filter
	 (fn (G, _, _, _) => leq_score (max_time_progress, whattime G))
	 cfs
  end
*)

(* Heuristic 6. Maximize time progress by triggering events ASAP. *)
fun heuristic_speedup_event_occ (cfs : TESL_ARS_conf list) =
  let
    val clock_decl = List.foldl (fn ((G, _, frun, _), l) => uniq (l @ (clocks_of_system G) @ (clocks_of_tesl_formula frun))) [] cfs
    fun next_event_time (frun: TESL_formula): tag option list =
      let
	   val frun = List.map (fn Sporadic (c, tag) => WhenTickingOn (c, tag, c) | f => f) frun
      in
	   List.map (fn c0 => 
			  case List.find (fn WhenTickingOn (c, tag, _) => c0 = c andalso is_tag_constant tag andalso (List.all (fn WhenTickingOn (c', tag', _) => not (c = c' andalso is_tag_constant tag') orelse ::<= (tag, tag') | _ => true) frun) | _ => false) frun of
			      NONE                          => NONE
			    | SOME (WhenTickingOn (_, tag, _)) => SOME tag
			    | _ => raise UnexpectedMatch
		     ) clock_decl
      end
    fun leq_score (l1, l2) = case (l1, l2) of
				     ([], []) => true
				   | (tago1 :: l1', tago2 :: l2') => (case (tago1, tago2) of
										  (NONE, NONE) => true
							 			| (SOME _, NONE) => false
										| (NONE, SOME _) => true
										| (SOME tag1, SOME tag2) => ::<= (tag1, tag2) andalso leq_score (l1', l2')
									  )
				   | _ => raise UnexpectedMatch
    val MINSCORE = List.map (fn _ => NONE) clock_decl
    fun max_score (l1, l2) = if leq_score (l1, l2) then l2 else l1
    val max_time_progress: tag option list =
	 List.foldl (fn ((_, _, frun, _), n) => max_score (n, next_event_time frun)) MINSCORE cfs
  (* todo *)
  in
    List.filter (fn (_, _, frun, _) => leq_score (max_time_progress, next_event_time frun)) cfs
  end



exception Unreferenced_heuristic
fun heuristic_ref_table (f: TESL_atomic) : (TESL_ARS_conf list -> TESL_ARS_conf list) =
  case f of
    DirHeuristic "asap"                             => heuristic_minimize_ticks
							       o heuristic_speedup_event_occ
							       o heuristic_minimize_floating_ticks
								o heuristic_minimize_unsolved_affine
  | DirHeuristic "minimize_ticks"                   => heuristic_minimize_ticks
  | DirHeuristic "speedup_event_occ"                => heuristic_speedup_event_occ
  | DirHeuristic "minimize_floating_ticks"          => heuristic_minimize_floating_ticks
  | DirHeuristic "minimize_unsolved_affine"         => heuristic_minimize_unsolved_affine
  | DirHeuristic "no_empty_instants"	          => heuristic_no_empty_instants
  | DirHeuristic "maximize_reactiveness"            => heuristic_maximize_reactiveness
  | DirHeuristic _                                  => raise Unreferenced_heuristic
  | _                                               => raise UnexpectedMatch

fun heuristic_combine
  (spec: TESL_formula)
  : (TESL_ARS_conf list -> TESL_ARS_conf list) =
  case spec of
     [] => (fn x => x)
   | _  => List.foldl
		 (fn (hname, hcurrent) => (heuristic_ref_table hname) o hcurrent)
		 (fn x => x)
		 spec


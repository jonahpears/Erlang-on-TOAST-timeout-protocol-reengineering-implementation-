%% @doc Interleaving composition and decomposition of protocols
-module(interleave).
-compile(export_all).
-compile(nowarn_export_all).

%% @doc Protocol format
%% Notes:
%%   - Recursion variables are represented as string()
%%   - Actions, labels, and assertion names are represented as atom()
%%   - Control branches are represented as a list of atom/protocol pairs
%%   - The atom endP is used to end a protocol because "end" is a reserved keyword.
-type protocol () :: {'act', atom(), protocol()}
                   | {'branch', [ {atom(), protocol()} ]}
                   | {'assert', atom(), protocol()}
                   | {'require', atom(), protocol()}
                   | {'consume', atom(), protocol()}
                   | {'rec', string(), protocol()}
                   | {'rvar', string()}
                   | 'endP'.


% # Examples
e1() ->
  {act, n, endP}.

e2() ->
  {require, n, {act, x, endP}}.

e3() ->
  {assert, n, {act, y, endP}}.

e4() ->
  {branch, [{l, {act, b, {assert, n, endP}}} ,{r, {act, c, {assert, n, endP}}}]}.

e5() ->
  {branch, [{l, {assert, n, endP}} ,{r, {assert, n, endP}}, {m, {assert, n, endP}}]}.

e6() ->
  {branch, [{l, {require, n, endP}} ,{r, {act, c, endP}}, {m, {assert, n, endP}}]}.

e7() ->
  {act, r_pwd, {branch, [{ok, {assert, n, endP}},{fail, endP}]}}.

e8() ->
  {require, n, {act, do_banking, endP}}.

e9() ->
  {rec, "x", {act, a, {act, b, {rvar, "x"}}}}.

e10() ->
  {rec, "y", {act, a, {branch, [{l, {act, b, {require, n, endP}}}
                               ,{r, {rvar, "y"}}]}}}.

bank() ->
  {require, pin, {rec, t, {branch, [{payment, {consume, tan,{act, r_payment,  {rvar, t}}}},
                                          {statement, {act, s_statement, {rvar, t}}},
                                          {logout, endP}]
                          }
                  }
  }.

pintan() ->
  {act, r_pin, {branch, [
                                    {ok, {assert, pin, {rec, r, ctan()}}},
                                    {fail, endP}]
                }
  }.

ctan() ->
  {act, s_id, {act, r_tan, {branch, [{ok, {assert, tan, {rvar, r}}},
                                            {fail, {rvar, r}}]
                            }
              }
  }.

pin() ->
  {act, r_pin, {branch, [{ok, {assert, pin, endP}},
                                {fail, endP}]
                }
  }.

tan() ->
  {require, pin, {rec, r, {act, s_id, {act, r_tan, {branch, [{ok, {assert, tan, {rvar, r}}},
                                                              {fail, {rvar, r}}]
                                                    }
                                      }
                          }
                  }
  }.


%% @doc Pretty print protocols
-spec pprint(protocol()) -> string().
pprint({act, Act, P}) ->
  atom_to_list(Act) ++ "." ++ pprint(P);
pprint({branch, Branches}) ->
  "{" ++ pprintBranches(Branches) ++ "}";
pprint({assert, N, P}) ->
  "assert(" ++ atom_to_list(N) ++ ")." ++ pprint(P);
pprint({require, N, P}) ->
  "require(" ++ atom_to_list(N) ++ ")." ++ pprint(P);
pprint({consume, N, P}) ->
  "consume(" ++ atom_to_list(N) ++ ")." ++ pprint(P);
pprint({rec, BoundVar, P}) ->
  "nu " ++ BoundVar ++ " . (" ++ pprint(P) ++ ")";
pprint({rvar, Var}) ->
  Var;
pprint(endP) ->
  "end".

%% @doc Substitution
-spec subst(protocol(), string(), string(), [string()]) -> protocol().
subst({act, Act, P}, BV1, BV2, A) -> {act, Act, subst(P, BV1, BV2, A)};
subst({assert, N, P}, BV1, BV2, A) -> {assert, N, subst(P, BV1, BV2, A)};
subst({require, N, P}, BV1, BV2, A) -> {require, N, subst(P, BV1, BV2, A)};
subst({consume, N, P}, BV1, BV2, A) -> {consume, N, subst(P, BV1, BV2, A)};
subst({branch, LiSi}, BV1, BV2, A) ->
  {branch, for(LiSi, fun({Li, Si}) -> {Li, subst(Si, BV1, BV2, A)} end)};
subst({rec, BV3, P}, BV1, BV2, A) ->
  case lists:member(BV1, A) of
    true -> {rec, BV3, subst(P, BV1, BV2, A)};
    false -> {rec, BV3, subst(P, BV1, BV2, A ++ [BV3])}
  end;
subst({rvar, BV1}, BV1, BV2, A) ->
  case lists:member(BV1, A) of
    true -> {rvar, BV1};
    false -> {rvar, BV2}
  end;
subst({rvar, BV3}, _, _, _) -> {rvar, BV3};
subst(endP, _ , _ , _ ) -> endP.

%% @doc Auxiliary printers
%% Prints a branch
pprintBranch({Label, P}) -> atom_to_list(Label) ++ " : " ++ pprint(P).
% Prints a list of branches
pprintBranches([])     -> "";
pprintBranches([B])    -> pprintBranch(B);
pprintBranches([B|BS]) -> pprintBranch(B) ++ "; " ++ pprintBranches(BS).

%% @doc Assertedness
% WIP: defaults to well-asserted
-spec asserted([atom()], protocol()) -> [atom()] | 'illAsserted'.
asserted(A , endP) -> A;
asserted(A, {rvar, _}) -> A;
asserted(A, {act, _, P}) -> asserted(A, P);
asserted(A, {branch, LiSi}) ->
  Abranches = for(LiSi, fun({_,Si}) -> asserted(A, Si) end),
  case listAsserted(Abranches) of
    true -> listIntersect(Abranches);
    false -> 'illAsserted'
  end;
asserted(A, {require, N, P}) ->
  case lists:member(N, A) of
    true -> asserted(A, P);
    false -> 'illAsserted'
  end;
asserted(A, {consume, N, P}) ->
  case lists:member(N, A) of
    true -> asserted(lists:delete(N,A), P);
    false -> 'illAsserted'
  end;
asserted(A, {assert, N, P}) ->
  case lists:member(N, A) of
    true -> asserted(A, P);
    false -> asserted(A ++ [N], P)
  end;
asserted(A, {rec, _, P}) ->
  case asserted(A, P) of
    illAsserted -> illAsserted;
    B -> lists:usort(B ++ A)
  end.
wellAsserted(A, PS) ->
  case asserted(A, PS) of
    illAsserted -> false;
    _           -> true
  end.

%% @doc Helper functions for assertedness
listAsserted([A|Alist]) ->
  case A of
    illAsserted -> false;
    _ -> listAsserted(Alist)
  end;
listAsserted([]) -> true.

listIntersect(A) ->
  sets:to_list(sets:intersection(for(A, fun(X) -> sets:from_list(X) end))).

%% @doc Helper functions of binders
%%Predicate on whether protocol P has all its free variables in environment N
bound(P, N) ->
  case P of
    {act, _, R} -> bound(R,N);
    {assert, _, R} -> bound(R,N);
    {require, _, R} -> bound(R,N);
    {consume, _, R} -> bound(R,N);
    {branch, LiSi} -> lists:all(fun(X) -> X end, for(LiSi, fun({_, Si})-> bound(Si,N) end) );
    {rec, T, R} -> bound(R,N ++ [T]);
    {rvar, T} -> lists:member(T,N);
    endP -> true
  end.

%% @doc Interleaving
%% Helper for plumbing non-determinstic results (represented as lists)
%% into functions which are non-determinstic (return a list of results)
-spec bind([A], fun((A) -> [B])) -> [B].
bind([], _F)    -> [];
bind([X|XS], F) -> F(X) ++ bind(XS, F).

%% @doc Basically just flip map
-spec for([A], fun((A) -> B)) -> [B].
for(XS, F) -> lists:map(F, XS).

%% @doc Remove duplicate elements
-spec nub([A]) -> [A].
nub(X) -> nub(X, []).
nub([], Clean) -> Clean;
nub([X|Xs], Clean) ->
    case lists:member(X, Clean) of
        true -> nub(Xs, Clean);
        false -> nub(Xs, Clean ++ [X])
    end.

%% @doc Compute a covering of a set (with two partitions)
twoCovering([])  -> [];
twoCovering([A]) -> [{[A], []}, {[], [A]}];
twoCovering([A|AS]) ->
  bind(twoCovering(AS), fun({XS, YS}) -> [{[A|XS], YS}, {XS, [A|YS]}] end).

%% @doc Take the largest list in a list of lists
maximalPossibility(XS) -> maximalPoss(XS, []).
maximalPoss([], Max) -> Max;
maximalPoss([XS|XSS], Max) when length(XS) >= length(Max) -> maximalPoss(XSS, XS);
maximalPoss([_|XSS], Max)  -> maximalPoss(XSS, Max).

% Top-level
-spec interleave(protocol(), protocol()) -> [protocol ()].
%% @doc Wraps the main function and passes in empty environments
interleave(S1, S2) -> nub(interleaveTop(strong, [], [], [], S1, S2)).

-spec interleaveWeak(protocol(), protocol()) -> [protocol ()].
%% @doc Wraps the main function and passes in empty environments
interleaveWeak(S1, S2) -> nub(interleaveTop(weakWeak, [], [], [], S1, S2)).

-spec interleaveWeakStrong(protocol(), protocol()) -> [protocol ()].
%% @doc Wraps the main function and passes in empty environments
interleaveWeakStrong(S1, S2) ->
    nub(interleaveTop(weakStrong, [], [], [], S1, S2)).

%% @doc n-way Cartesian product
-spec nCartesian([[A]]) -> [[A]].
nCartesian([]) -> [];
%% XS is one list, [XS] is the list of one list of lists
nCartesian([XS]) -> lists:map(fun (X) -> [X] end, XS);
nCartesian([XS|XSS]) ->
  bind(XS, fun(X) -> bind(nCartesian(XSS), fun(YS) -> [[X|YS]] end) end).

%% @doc Takes
%%   - a list TL of recursion variables [string()] bound on the left
%%   - a list TR of recursion variables [string()] bound on the right
%%   - a list of atoms for the asserted names
%%   - left protocol
%%   - right protocol
%% This function should be used in all recursive calls since it also implements
%% the symmetry rule, where as interleaveMain does the main, asymmetrical work
-spec interleaveTop(atom(), [string()], [string()], [atom()], protocol(), protocol()) -> [protocol()].
%% [sym] rule
interleaveTop(WeakFlag, TL, TR, A, S1, S2) ->
  interleaveMain(WeakFlag, TL, TR, A, S1, S2) ++
    interleaveMain(WeakFlag, TR, TL, A, S2, S1).

%% @doc Asymmetrical (left-biased) rules
-spec interleaveMain(atom(), [string()], [string()], [atom()], protocol(), protocol()) -> [protocol()].
%% [end] rule
interleaveMain(_, _, _, _, endP, endP) -> [endP];
%% [act] rule
interleaveMain(WeakFlag, TL, TR, A, {act, P, S1}, S2) ->
  for(interleaveTop(WeakFlag, TL, TR, A, S1, S2), fun(S) -> {act, P, S} end);
%% [require] rule
interleaveMain(WeakFlag, TL, TR, A, {require, N, S1}, S2) ->
  case lists:member(N, A) of
    true ->
      % Induct
      for(interleaveTop(WeakFlag, TL, TR, A, S1, S2)
        , fun(S) -> {require, N, S} end);
    false -> [] % Fail
  end;
%% [consume] rule
interleaveMain(WeakFlag, TL, TR, A, {consume, N, S1}, S2) ->
  case lists:member(N, A) of
    true ->
      % Induct
      for(interleaveTop(WeakFlag, TL, TR, lists:delete(N, A), S1, S2)
        , fun(S) -> {consume, N, S} end);
    false -> [] % Fail
  end;
%% [assert] rule
interleaveMain(WeakFlag, TL, TR, A, {assert, P, S1}, S2) ->
  for(interleaveTop(WeakFlag, TL, TR, [P|A], S1, S2)
      , fun(S) -> {assert, P, S} end);

%% [bra] rule
%% if for branches S0, S1, S2 we get the following possible interleavings with S2
%%   S0'_0, S0'_1
%%   S1'_0, S1'_1, S1'_2
%%   S2'_0, S2'_1, S3'_2
%% then nCartesian takes all possible combinations

%% LiSi is the list of label-protocol pairs
interleaveMain(_, _, _, _, {branch, []}, _) -> errorEmptyBranch;

%% [branch]
interleaveMain(WeakFlag, TL, TR, A, {branch, LiSi}, S2) ->
  Covering =
    case WeakFlag of
      % La is whole set
      strong -> [{LiSi, []}];
      % otherwise La,Lb partitions where La is non-empty
      % Compute the two covering, of which the last has Ia = \emptyset so drop it
      _      -> lists:droplast(twoCovering(LiSi))
    end,
  Possibilities = for(Covering,
    fun ({Ia, Ib}) ->
    % Good parition if all Sb are well asserted
    case lists:all(fun ({_, Sib}) -> wellAsserted(A, Sib) end, Ib) of
      % Good parition
      true -> AllCombinations = nCartesian(for(Ia,
                    fun ({Li, Si}) ->
                    % Find all intereleavings for Si with S2 - put with its label
                    % with possible weakening modes
                    for(interleaveTop(WeakFlag, TL, TR, A, Si, S2),
                          fun(Sip) -> {Li, Sip} end)
                    end)),
        for(AllCombinations, fun(LiSip) -> {branch, LiSip ++ Ib} end);

      % Bad partition Ib is not all well-asserted
      false -> []
    end
  end),
  case WeakFlag of
    strong     -> lists:concat(Possibilities);
    weakWeak   -> lists:concat(Possibilities);
    weakStrong -> maximalPossibility(Possibilities)
  end;
%% [rec1]
interleaveMain(WeakFlag, TL, TR, A, {rec, BV1, S1}, {rec, BV2, S2}) ->
  % Top(S1) not a recursion
  case S1 of
    {rec, _, _} -> [];
    _ -> for(
          interleaveTop(WeakFlag, TL ++ [BV1], TR, A, S1, {rec, BV2, S2})
          , fun(S) ->
          case wellAsserted(A, {rec, BV1, S}) of
                        true -> {rec, BV1, S};
                        false -> []
                      end
            end)
  end;
 %% [rec3]
interleaveMain(_, _, _, A, {rec, BV1, S1}, endP) ->
  case wellAsserted(A, {rec, BV1, S1}) and bound({rec, BV1, S1},[]) of
    true -> [{rec, BV1, S1}];
    false -> []
  end;
 %% [rec2]
interleaveMain(WeakFlag, TL, TR, A, {rec, BV1, S1}, S2) ->
  case S1 of
    % TOP check
    {rec, _, _} -> [];
    _ -> lists:append(for(TR, fun(S)->
            interleaveTop(WeakFlag, TL, TR, A, subst(S1, BV1, S, []), S2) end))
  end;
%% [call]
interleaveMain(_, TL, TR , _, {rvar, BV1}, {rvar, BV1}) ->
  case lists:member(BV1, TL) or lists:member(BV1, TR) of
    true -> [{rvar, BV1}];
    false -> []
  end;
%% check top and well assertedness
interleaveMain(_, _, _, _, _, _) -> [].

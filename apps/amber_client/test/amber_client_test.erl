-module(amber_client_test).

-include_lib("proper/include/proper.hrl").
% -define(NODEBUG, 1).
-include_lib("eunit/include/eunit.hrl").
-include ("include/drivermsg_pb.hrl").
-include ("include/common.hrl").

-compile(export_all).


-define(START_APP(AppName),  case application:start(AppName) of
                               ok -> ok;
                               {error, {already_started, _}} -> ok
                             end).

receiver() ->
  receive
    stop                                    -> stop;
    {F,Xs} when is_function(F), is_list(Xs) -> apply(F,[F|Xs]), receiver()
  after 1000 -> kthxbye
  end.

proper_test_() ->
  {setup, fun proper_test_start_all/0, fun proper_test_stop_all/1, fun proper_test_main/1}.

proper_test_start_all() ->
  ?START_APP(mnesia),
  ?START_APP(amber),
  ?START_APP(amber_client).

proper_test_stop_all(_) ->
  application:stop(amber_client),
  application:stop(amber),
  application:stop(mnesia).


proper_test_main(_) ->
  [
    ?_assertNotEqual(false, lists:keyfind(amber, 1, application:which_applications())),
    ?_assertNotEqual(false, lists:keyfind(amber_client, 1, application:which_applications())),
    ?_assertEqual(true, is_pid(whereis(qc_driver_echo_a))), 
    proper:module(?MODULE, [{to_file, user}])
  ].

prop_warmup() ->
  ?FORALL(Lst, [any()], lists:reverse(lists:reverse(Lst)) =:= Lst).


prop_msg_from_remote_client() ->
  ?FORALL(Xs,
          list(pos_integer()), % maksymalny przechodzący test: integer(1,22)
    begin
      lists:all(fun(X) -> X=:=true end,
                lists:map(fun msg_send_receive/1, Xs))
    end).

msg_send_receive(MsgNumber) ->
  {DevT,DevI} = {2,3},
  SynNum = amber_client:get_synnum(),
  Hdr = #driverhdr{devicetype=DevT, deviceid=DevI},
  MsgBinary = drivermsg_pb:encode_drivermsg(#drivermsg{ type='DATA',
                                                        synnum=SynNum,
                                                        acknum=SynNum }), % acknum nie powinno niby być w wysyłanym żądaniu, ale co tam
  Key = #dispd_key{dev_t=DevT, dev_i=DevI, synnum=SynNum},
  Val = #dispd_val{recpid=self()},

  amber_client:register_receiver(Key, Val),
  [amber_client:send_to_amber(Hdr, MsgBinary) || _ <- lists:seq(1,MsgNumber)],
  counter_acm(MsgNumber,MsgNumber,DevT,DevI,SynNum).

counter_acm(MsgNumber,N,DevT,DevI,SynNum) when N>0 ->
  receive #amber_client_msg{hdr=#driverhdr{devicetype=DevT, deviceid=DevI}, msg=#drivermsg{acknum=SynNum}} ->
    counter_acm(MsgNumber,N-1,DevT,DevI,SynNum)
  after 500 ->
    ?debugFmt("counter_acm ma jeszcze do otrzymania ~p, dostał n=~p z msgnumber=~p, synnum=~p", [N,MsgNumber-N,MsgNumber,SynNum])
  end;
counter_acm(_,_,_,_,_) -> true.
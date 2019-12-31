#!/usr/bin/env escript


main(_) ->
    SelfNode = list_to_atom( "grant" ++ "@" ++ net_adm:localhost()),
    CookieName = 'monster',
    XQERL = list_to_atom(os:getenv("NAME")),
    HostName = list_to_atom(element(2,inet:gethostname())),
    
    io:format("Script: ~p~n", [list_to_atom(escript:script_name())]),
    net_kernel:start([SelfNode, longnames]),
    erlang:set_cookie(SelfNode,CookieName),
    io:format(" Alive: ~p~n", [is_alive()]),
    io:format("  Ping: ~p~n", [net_adm:ping(XQERL)]),
    io:format(" Names: ~p~n", [net_adm:names()]),
    io:format(" os version: ~p~n", [os:version()]),
    io:format("   Pid: ~p~n", [os:getpid()]),
    io:format(" xqerl: ~p~n", [os:find_executable('xqerl')]),
    io:format(" hostname: ~p~n", [HostName]),
    io:format(" hostByName: ~p~n", [ element(2,inet:gethostbyname(HostName))]),
    io:format(" getifaddrs: ~p~n", [ element(2,inet:getifaddrs())]),
    io:format("   xqerl: ~p~n", [os:cmd("ls")]),
    {ok, Sock } = gen_tcp:connect(HostName, 8081, [{active,false}, {packet, 2}]),
    io:format("    connect: ~p~n", [  Sock ]),
    gen_tcp:send(Sock, "Some Data"),
    Reply = gen_tcp:recv(Sock,0),
    gen_tcp:close(Sock),
    io:format(" reply: ~p~n", [ Reply ]).
    





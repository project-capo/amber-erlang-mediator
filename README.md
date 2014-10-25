amber-erlang-mediatora
======================

It is a project made by Konrad Gądek and Michał Konarski. Project contains:

  - mediator (Erlang)
  - client application (Erlang)

Requirements
------------

  * `g++` with `make`
  * `erlang` version R15B, R16B

How to use (Makefile)
---------------------

Simply.

    make all
    make test

Run with scripts:

    ./start_amber.sh        # server in background
    ./start_devel_amber.sh  # server in foreground
    ./start_client.sh       # client

Stop using `[Ctrl]+[c]` in foreground mode or by command `killall heart` in background mode.

How to contribute
-----------------

Clone this repo and setup your enviroment. Next, change what you want and make pull request.

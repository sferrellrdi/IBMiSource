000100211110**free
000200211110ctl-opt dftactgrp(*no) actgrp(*caller) option(*srcstmt: *nodebugio: *noxref);
000300211110// @Program.... DEMO5CALL
000400211110// @Purpose.... DEMO5CALL - Created using the template FFHEADER
000500211110// @Author..... Sferrell
000600211110// @Date ...... Nov 10, 2021
000700211110//
000800211110// Change log:
000900211110// mon-dd-yyyy  tag      user      description
001000211110// -----------  -------- --------- ---------------------------------------
001100211110// Nov 10, 2021 Created  Sferrell  Inital creation
001200211110//
001300211110// ----------------------------------------------------------------------
001400211110
001500211110// Declarations
001600211110dcl-pi *n;
001700211110  pStateIn char(2);
001800211110end-pi;
001900211110
002000211110dcl-pr callAPI extpgm('DEMO5');
002100211110  pState char(2);
002200211110end-pr;
002300211110
002400211110// Mainline
002500211110callAPI(pStateIn);
002600211110
002700211110return;

program bbs;

{$mode objfpc}{$H+}

uses
  BrookApplication, Brokers, synacode, Mapping, main, forums, RegisterUsr,
  posts, Logout, info, myAccnt, newThm, newPost, change, legal, fevent, Menu,
  upst, find, frslt, geoinfo, news;

{$R *.res}

begin
  BrookApp.Run;
end.

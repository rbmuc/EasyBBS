unit Brokers;

{$mode objfpc}{$H+}

interface

uses
  BrookFCLFCGIBroker, SysUtils, BrookUtils, BrookHTTPConsts;

implementation
const
  HTML_TPL = '<html><head><title>%s</title><style>body{margin:0;padding:30px;font:12px/1.5 Helvetica,Arial,Verdana,sans-serif;}h1{margin:0;font-size:48px;font-weight:normal;line-height:48px;}strong{display:inline-block;width:65px;}</style></head><body><h1>%s</h1><br />%s%s</body></html>';

function HTML(const ATitle, AError, AMsg, ATrace: string): string;
  begin
    Result := Format(HTML_TPL, [ATitle, AError, AMsg, ATrace]);
  end;

initialization
  BrookSettings.Charset := BROOK_HTTP_CHARSET_UTF_8;
  BrookSettings.Page404 := HTML('Page not found', '404 - Page not found', 'Click <a href="www.bergertime.de">here</a> to go to home page ...', '');
  BrookSettings.Page500 := HTML('Internal server error','500 - Internal server error', 'Error: @error','<br /><br />Trace: @trace');
  BrookSettings.DirectoryForUploads := 'C:\Apache22\fcgi-bin\upld';
end.


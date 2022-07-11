unit uShell;

interface

uses Forms, Classes, SysUtils, ShellApi, ShlObj, ClipBrd, Windows;


//Shell
function Shell_Str(Strs: TStrings) : string;
function Shell_DataOperations (const Source, Target: string; Operacia, Flags: Integer): Boolean;

//Clipboard
procedure Clipboard_DataSend(const DataPaths: TStrings; const MoveType: integer);
procedure ClipBoard_DataPaste(const Target: string);
function  ClipBoard_GetDataList(h: THandle) : TStrings;

implementation




{$REGION                           '   Shell   '}


//------------------------------------------------------------------------------ Str
function Shell_Str(Strs: TStrings) : string;
{
Функция преобразует TStirngs в спец-строку для Shell
это спец-строка для буфера обмена, где строки разделены знаком #0
и вся спец-строка строка заканчивается #0#0
}
var
//s: string; //uses SysUtils
i: Integer;

begin

//s := StringReplace(Strs.Text, #13#10, #0, [rfReplaceAll]);
//s := trim(s) + #0#0;
//Result := s;


for i := 0 to Strs.Count - 1
do Result := Result + Strs.Strings[i] + #0;

Result := Result + #0;

end;


//------------------------------------------------------------------------------ Operation
function Shell_DataOperations (const Source, Target: string; Operacia, Flags: Integer): Boolean;
{
Функция для копирования/вырезания/перименования/удаления данныx средсвами API

uses ShellAPI

source - Special Shell Str of Data

operacia:
FO_COPY
FO_MOVE
FO_RENAME
FO_DELETE

flags:
FOF_ALLOWUNDO         - Если возможно, сохраняет информацию для возможности UnDo. Если вы хотите не просто удалить файлы, а переместить их в корзину, должен быть установлен флаг/
FOF_CONFIRMMOUSE      - Не реализовано.
FOF_FILESONLY         - Если в поле pFrom установлено *.*, то операция будет производиться только с файлами.
FOF_MULTIDESTFILES    - Указывает, что для каждого исходного файла в поле pFrom указана своя директория - адресат.
FOF_NOCONFIRMATION    - Отвечает "yes to all" на все запросы в ходе опеации.
FOF_NOCONFIRMMKDIR    - Не подтверждает создание нового каталога, если операция требует, чтобы он был создан.
FOF_RENAMEONCOLLISION - В случае, если уже существует файл с данным именем, создается файл с именем "Copy #N of..."
FOF_SILENT            - Не показывать диалог с индикатором прогресса.
FOF_SIMPLEPROGRESS    - Показывать диалог с индикатором прогресса, но не показывать имен файлов.
FOF_WANTMAPPINGHANDLE - Вносит hNameMappings элемент. Дескриптор должен быть освобожден функцией SHFreeNameMappings
}

var SHOS: TSHFileOpStruct;

begin

FillChar (SHOS, SizeOf(SHOS), #0);

SHOS.Wnd    :=  0;
SHOS.wFunc  :=  operacia;
SHOS.pFrom  :=  PCHAR(source);
SHOS.pTo    :=  PCHAR(target);
SHOS.fFlags :=  flags;

Result := (SHFileOperation(SHOS) = 0) and (not SHOS.fAnyOperationsAborted);


end;


{$ENDREGION}




{$REGION '   Clipboard   '}



//============================================================================== Send
procedure Clipboard_DataSend(const DataPaths: TStrings; const MoveType: integer);
{
Отправляет файлы/папки в буфер обмена на
5 = копирование(будто вы нажали Ctrl+C)
2 = вырезку(будто вы нажали Ctrl+X)  DROPEFFECT_MOVE
чтоб потом можно было вставить(Ctrl+V) эти данные в любом файловом менеджере.

uses ShlObj, ClipBrd, Windows;
}

var
DropFiles: PDropFiles;
hGlobal: THandle;
iLen: Integer;
f: Cardinal;
d: PCardinal;
DataSpecialList: string; //список адресов(FullPaths) файлов/папок которые надо копировать
begin

  try
    Clipboard.Open;
  except
    on E: Exception do
    begin
      xLog(E.Message);
      Exit;
    end;
  end;

  try
    Clipboard.Clear;

    //преобразовываем в спец-строку
    DataSpecialList := Shell_Str(DataPaths);


    iLen := Length(DataSpecialList) * SizeOf(Char);
    hGlobal := GlobalAlloc(GMEM_SHARE or GMEM_MOVEABLE or GMEM_ZEROINIT, SizeOf(TDropFiles) + iLen);
    Win32Check(hGlobal <> 0);
    DropFiles := GlobalLock(hGlobal);
    DropFiles^.pFiles := SizeOf(TDropFiles);

    {$IFDEF UNICODE}
    DropFiles^.fWide := true;
    {$ENDIF}

    Move(DataSpecialList[1], (PansiChar(DropFiles) + SizeOf(TDropFiles))^, iLen);
    SetClipboardData(CF_HDROP, hGlobal);
    GlobalUnlock(hGlobal);

    //FOR COPY
    begin
       f := RegisterClipboardFormat(CFSTR_PREFERREDDROPEFFECT);
       hGlobal := GlobalAlloc(GMEM_SHARE or GMEM_MOVEABLE or GMEM_ZEROINIT, sizeof(dword));
       d := PCardinal(GlobalLock(hGlobal));
       d^ := MoveType;//2-Cut, 5-Copy
       SetClipboardData(f, hGlobal);
       GlobalUnlock(hGlobal);
    end;
  finally
    Clipboard.Close;
  end;

end;


//============================================================================== Type
function Clipboard_SendType : integer;
{
5 - copy
2 - cut

Функция определяет на что посланы данные в буфер: на вырезку или копирование

Эта функция создаваласть специально для функции ClipBoard_DataPaste,
чтоб было понятно что делать: копировать или вырезать.
}
var
   ClipFormat,hn: Cardinal;
   szBuffer: array[0..511] of Char;
   FormatID: string;
   pMem: Pointer;
begin
  Result := 0;

  if not OpenClipboard(Application.Handle) then
    Exit;

  try
    ClipFormat := EnumClipboardFormats(0);

    while (ClipFormat <> 0) do
    begin

     GetClipboardFormatName(ClipFormat, szBuffer, SizeOf(szBuffer));
     FormatID := string(szBuffer);

     if SameText(FormatID,'Preferred DropEffect')
     then
     begin
           hn := GetClipboardData(ClipFormat);
           pMem := GlobalLock(hn);
           Move(pMem^, Result, 4);// <- теперь в Result тип операции
           GlobalUnlock(hn);
           Break;
     end;

     ClipFormat := EnumClipboardFormats(ClipFormat);
  end;
  finally
       CloseClipboard;
  end;

end;


//============================================================================== Paste
procedure ClipBoard_DataPaste(const Target: string);
{
Эта функция вставит из буфера обмена файлы/папки,
которые копировали/вырезали(Ctrl+C / Ctrl+X) в буфер в каком-либо фаловом менеджере(Проводник, ТоталКоммандер)

Target - папка в которую будет вставлены данные
Clipboard_OperationType - подфункция которая определяет что надо сделать: Копировать или Вырезать
}

var
  h : THandle;
  Sourse, sr : string;

begin

  //Если то, что находиться в буфере
  //НЕ является файлами/папками, которые копированы/вырезаны, то выходим
  //CF_HDROP - дескриптор который идентифицирует список файлов.
  //Прикладная программа может извлечь информацию о файлах, передавая дескриптор функции DragQueryFile.
  if not Clipboard.HasFormat(CF_HDROP) then exit;


    try
      Clipboard.Open;
    except
      on E: Exception do
      begin
        xLog(E.Message);
        Exit;
      end;
    end;

  try
    h := Clipboard.GetAsHandle(CF_HDROP);

    if h <> 0
    then
    begin

          Sourse := Shell_Str( ClipBoard_GetDataList(h) );

          sr := Copy( Sourse, 0, Pos(#0, Sourse)-1 );  //Path №1
          sr := ExtractFilePath(sr);           //Родительская папка Data


          if IncludeTrailingBackslash(sr) = IncludeTrailingBackslash(Target)

          then//Делаем копию фала: откуда copy туда и paste
          begin
                case Clipboard_SendType
                of
                   5: Shell_DataOperations(sourse, target, FO_COPY, FOF_SIMPLEPROGRESS or FOF_RENAMEONCOLLISION );
                   2: Shell_DataOperations(sourse, target, FO_MOVE, FOF_SIMPLEPROGRESS );
                end;
          end

          else
          begin
                case Clipboard_SendType
                of
                   5: Shell_DataOperations(sourse, target, FO_COPY, FOF_SIMPLEPROGRESS );
                   2: Shell_DataOperations(sourse, target, FO_MOVE, FOF_SIMPLEPROGRESS );
                end;
          end;
    end;

  finally
      Clipboard.Close;
  end;
end;


//============================================================================== List
function ClipBoard_GetDataList(h: THandle) : TStrings;
{
Вы нажали Ctrl+C или Ctrl+X => послали данные в буфер обмена.
Так вот эта функция возвращает список файлов/папок, которые посланы в буфер.
}

var
  FilePath: array [0..MAX_PATH] of Char;
  i, FileCount: Integer;
begin
  Result := nil;

  if h = 0 then
    Exit;

  Result := TStringList.Create;

  FileCount := DragQueryFile(h, $FFFFFFFF, nil, 0);

  for i := 0 to FileCount - 1 do
  begin
    DragQueryFile(h, i, FilePath, SizeOf(FilePath));
    Result.Add(FilePath);
  end;
end;




{$ENDREGION}




end.

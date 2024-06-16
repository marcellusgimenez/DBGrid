unit uEstudo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, Vcl.Grids, Vcl.DBGrids,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    conexao: TFDConnection;
    sqlProduto: TFDQuery;
    tblProdutoItem: TFDMemTable;
    DBGrid: TDBGrid;
    dsProduto: TDataSource;
    transacao: TFDTransaction;
    sqlProdutoCODIGO_PRODUTO: TIntegerField;
    sqlProdutoPRODUTO: TStringField;
    tblProdutoItemCODIGO_PRODUTO: TIntegerField;
    tblProdutoItemPRODUTO: TStringField;
    tblProdutoItemUNIDADE: TStringField;
    tblProdutoItemQUANTIDADE: TFloatField;
    tblProdutoItemVALOR_UNITARIO: TFloatField;
    tblProdutoItemsub_total: TCurrencyField;
    sqlProdutovalor_venda: TCurrencyField;
    sqlProdutoUNIDADE: TStringField;
    Button1: TButton;
    procedure tblProdutoItemCalcFields(DataSet: TDataSet);
    procedure DBGridColExit(Sender: TObject);
    procedure DBGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    procedure DimensionarGrid(dbg: TDBGrid);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if tblProdutoItem.RecordCount > 0 then tblProdutoItem.EmptyDataSet;

  tblProdutoItem.Open;
  tblProdutoItem.Insert;

  dbgrid.SetFocus;
end;

procedure TForm1.DBGridColExit(Sender: TObject);
begin

  if tblProdutoItem.State = dsinsert then  begin
    if DBGrid.SelectedIndex = 0 then begin
      sqlProduto.Close;
      sqlProduto.Params[0].AsInteger := tblProdutoItemCODIGO_PRODUTO.AsInteger;
      sqlProduto.Open();

      if sqlProduto.RecordCount > 0 then begin
        tblProdutoItemPRODUTO.Value := sqlProdutoPRODUTO.value;
        tblProdutoItemVALOR_UNITARIO.Value := sqlProdutovalor_venda.Value;
        tblProdutoItemUNIDADE.Value := sqlProdutoUNIDADE.Value;
        tblProdutoItemQUANTIDADE.Value := 1;
      end else begin
        ShowMessage('Produto não encontrado.');
        DBGrid.SelectedIndex := 0;
        abort;
      end;

    end;
  end;

  if DBGrid.SelectedIndex = 3 then begin
    if tblProdutoItemQUANTIDADE.Value < 1 then begin
      ShowMessage('Quantidade inválido. ');
      DBGrid.SelectedIndex := 3;
      abort;
    end;

  end;

end;

procedure TForm1.DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  dbgrid.Canvas.Brush.Color := $00f8f8f8;
  dbgrid.Canvas.font.Color := clblack;
  dbgrid.Canvas.fillrect(rect);
  TDBgrid(sender).DefaultDrawColumnCell(rect, dataCol, column, state);
end;

procedure TForm1.DBGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

  if key = VK_RETURN then begin
    case dbgrid.SelectedIndex of
      0: begin
        dbgrid.SelectedIndex := 3;
      end;

      2: begin
        dbgrid.SelectedIndex := 3;
      end

      else begin
        dbgrid.SelectedIndex := 0;
        tblProdutoItem.Insert;
      end

    end;
  end;

  if key = vk_cancel then begin
    tblProdutoItem.Cancel;
  end;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  // É só informar o seu DBgrid
  DimensionarGrid( DBGrid );
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  tblProdutoItem.Open;
  tblProdutoItem.Insert;
end;

procedure TForm1.tblProdutoItemCalcFields(DataSet: TDataSet);
begin
  tblProdutoItemsub_total.Value := tblProdutoItemQUANTIDADE.Value*tblProdutoItemVALOR_UNITARIO.Value;
end;

procedure TForm1.DimensionarGrid(dbg: TDBGrid);
type
  TArray = Array of Integer;
  procedure AjustarColumns(Swidth, TSize: Integer; Asize: TArray);
  var
    idx: Integer;
  begin
    if TSize = 0 then
    begin
      TSize := dbg.Columns.count;
      for idx := 0 to dbg.Columns.count - 1 do
        dbg.Columns[idx].Width := (dbg.Width - dbg.Canvas.TextWidth('AAAAAA')
          ) div TSize
    end
    else
      for idx := 0 to dbg.Columns.count - 1 do
        dbg.Columns[idx].Width := dbg.Columns[idx].Width +
          (Swidth * Asize[idx] div TSize);
  end;

var
  idx, Twidth, TSize, Swidth: Integer;
  AWidth: TArray;
  Asize: TArray;
  NomeColuna: String;
begin
  SetLength(AWidth, dbg.Columns.count);
  SetLength(Asize, dbg.Columns.count);
  Twidth := 0;
  TSize := 0;
  for idx := 0 to dbg.Columns.count - 1 do
  begin
    NomeColuna := dbg.Columns[idx].Title.Caption;
    dbg.Columns[idx].Width := dbg.Canvas.TextWidth
      (dbg.Columns[idx].Title.Caption + 'A');
    AWidth[idx] := dbg.Columns[idx].Width;
    Twidth := Twidth + AWidth[idx];

    if Assigned(dbg.Columns[idx].Field) then
      Asize[idx] := dbg.Columns[idx].Field.Size
    else
      Asize[idx] := 1;

    TSize := TSize + Asize[idx];
  end;
  if TDBGridOption.dgColLines in dbg.Options then
    Twidth := Twidth + dbg.Columns.count;

  // adiciona a largura da coluna indicada do cursor
  if TDBGridOption.dgIndicator in dbg.Options then
    Twidth := Twidth + IndicatorWidth;

  Swidth := dbg.ClientWidth - Twidth;
  AjustarColumns(Swidth, TSize, Asize);
end;

end.

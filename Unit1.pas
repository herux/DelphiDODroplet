unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Edit, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.TabControl,
  FMX.ListBox, Data.Bind.Controls, Fmx.Bind.Navigator, REST.Types, REST.Client,
  Data.Bind.Components, Data.Bind.ObjectScope, System.JSON, System.Math.Vectors,
  FMX.Controls3D, FMX.Layers3D;

type
  TForm1 = class(TForm)
    MaterialOxfordBlueSB: TStyleBook;
    WedgewoodLightSB: TStyleBook;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    Rectangle2: TRectangle;
    Edit1: TEdit;
    SearchEditButton1: TSearchEditButton;
    Label32: TLabel;
    Layout25: TLayout;
    Label17: TLabel;
    ListBox13: TListBox;
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    edtPAT: TEdit;
    Layout3D1: TLayout3D;
    Rectangle1: TRectangle;
    Image1: TImage;
    Image2: TImage;
    Label10: TLabel;
    Label11: TLabel;
    procedure edtPATKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure DoTrashButtonClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);

  private
    FPersonalAccessToken: string;
    { Private declarations }
    function CreateDroplet(): String;
    procedure DeleteDroplet(ADropletID: string;  AItemIndex: integer);
    function GetAllDroplet(APage: integer): TJSONObject;

    function CreateListBoxItem(AIndex: integer; AId: string; AName: string): TListBoxItem;
  public
    { Public declarations }
    property PersonalAccessToken: string read FPersonalAccessToken write FPersonalAccessToken;
  end;

const
  DO_DROPLET_BASE_PATH = 'https://api.digitalocean.com/v2/droplets';

var
  Form1: TForm1;

implementation

{$R *.fmx}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  CreateDroplet;
end;

function TForm1.CreateDroplet: String;
var
  LRestClient: TRESTClient;
  LRestRequest: TRESTRequest;
  LReqBody, LResp: TJSONObject;
  LItemLB: TListBoxItem;
begin
  LRestClient := TRESTClient.Create(DO_DROPLET_BASE_PATH);
  LRestRequest:= TRESTRequest.Create(nil);
  LReqBody :=  TJSONObject.Create;
  try
    // creating new droplet req body
    LReqBody.AddPair('name','DO.Delphi'+ListBox13.Count.ToString+'.Droplet');
    LReqBody.AddPair('region','nyc3');
    LReqBody.AddPair('size','s-1vcpu-1gb');
    LReqBody.AddPair('image','ubuntu-16-04-x64');
    LReqBody.AddPair('ssh_keys', TJSONArray.Create);
    LReqBody.AddPair('backups', TJSONBool.Create(false));
    LReqBody.AddPair('ipv6', TJSONBool.Create(True));
    LReqBody.AddPair('user_data', TJSONNull.Create);
    LReqBody.AddPair('private_networking',TJSONNull.Create);
    LReqBody.AddPair('volumes',TJSONNull.Create);
    LReqBody.AddPair('tags',TJSONArray.Create);

    LRestRequest.Method := rmPOST;
    LRestRequest.AddParameter('Authorization', 'Bearer ' + PersonalAccessToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
    LRestRequest.AddBody(LReqBody.ToJSON, TRESTContentType.ctAPPLICATION_JSON);
    LRestRequest.Client := LRestClient;
    LRestRequest.Execute;
    LResp := (LRestRequest.Response.JSONValue as TJSONObject).GetValue('droplet') as TJSONObject;
    LItemLB := CreateListBoxItem(ListBox13.Count, LResp.GetValue('id').Value, LResp.GetValue('name').Value);
    ListBox13.AddObject(LItemLB);
    Result := LRestRequest.Response.JSONText;
  finally
    LRestRequest.Free;
    LRestClient.Free;
    LReqBody.Free;
  end;
end;

function TForm1.CreateListBoxItem(AIndex: integer; AId: string; AName: string): TListBoxItem;
var
  vLayout: TLayout;
  vBtnTrash: TButton;
  vDroplLabel: TLabel;
begin
  Result := TListBoxItem.Create(ListBox13);
  vLayout := TLayout.Create(nil);
  vLayout.Align := TAlignLayout.Top;
  vLayout.Size.Height := 19;
  vLayout.Size.PlatformDefault := False;
  vLayout.Size.Width := 636;
  vBtnTrash:= TButton.Create(vLayout);
  vBtnTrash.StyleLookup := 'trashtoolbutton';
  vBtnTrash.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight, TAnchorKind.akBottom];
  vBtnTrash.Align := TAlignLayout.Right;
  vBtnTrash.ControlType := TControlType.Styled;
  vBtnTrash.Size.Height := 35;
  vBtnTrash.Size.PlatformDefault := False;
  vBtnTrash.Size.Width := 35;
  vBtnTrash.OnClick := DoTrashButtonClick;
  vBtnTrash.Tag := index;
  vBtnTrash.TagString := AId;
  vLayout.AddObject(vBtnTrash);
  vDroplLabel := TLabel.Create(vLayout);
  vDroplLabel.Align := TAlignLayout.Client;
  vDroplLabel.Text := AName;
  vLayout.AddObject(vDroplLabel);
  Result.AddObject(vLayout);
end;

procedure TForm1.DeleteDroplet(ADropletID: string; AItemIndex: integer);
var
  LRestClient: TRESTClient;
  LRestRequest: TRESTRequest;
begin
  LRestClient := TRESTClient.Create(DO_DROPLET_BASE_PATH + '/' + ADropletID);
  LRestRequest:= TRESTRequest.Create(nil);
  try
    try
      LRestRequest.Method := rmDELETE;
      LRestRequest.AddParameter('Authorization', 'Bearer ' + PersonalAccessToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
      LRestRequest.Client := LRestClient;
      LRestRequest.Execute;
      ListBox13.Items.Delete(AItemIndex);
    except
      on E:Exception do
        ShowMessage('Delete droplet failed');
    end;
  finally
    LRestRequest.Free;
    LRestClient.Free;
  end;
end;

procedure TForm1.DoTrashButtonClick(Sender: TObject);
begin
  DeleteDroplet((Sender as TButton).TagString, (Sender as TButton).Tag);
end;

procedure TForm1.edtPATKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  case Key of
    vkReturn: GetAllDroplet(1);
  end;
end;

function TForm1.GetAllDroplet(APage: integer): TJSONObject;
var
  LRestClient: TRESTClient;
  LRestRequest: TRESTRequest;
  LDroplets: TJSONArray;
  I: Integer;
  LLBDroplet: TListBoxItem;
  LLayout: TLayout;
  LBtnTrash: TButton;
  LDroplLabel: TLabel;
begin
  LRestClient := TRESTClient.Create(DO_DROPLET_BASE_PATH);
  LRestRequest:= TRESTRequest.Create(nil);
  try
    LRestRequest.Method := rmGET;
    LRestRequest.AddParameter('Authorization', 'Bearer ' + edtPAT.Text, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
    LRestRequest.Client := LRestClient;
    LRestRequest.Execute;
    Result := LRestRequest.Response.JSONValue as TJSONObject;
    LDroplets := Result.GetValue('droplets') as TJSONArray;
    I := 0;
    for I := 0 to LDroplets.Count - 1 do begin
      LLBDroplet := CreateListBoxItem(I,
        (LDroplets.Items[I] as TJSONObject).GetValue('id').Value,
        (LDroplets.Items[I] as TJSONObject).GetValue('name').Value);
      ListBox13.AddObject(LLBDroplet);
    end;
    PersonalAccessToken := edtPAT.Text;
    edtPAT.Visible := False;
  finally
    LRestRequest.Free;
    LRestClient.Free;
  end;
end;

end.

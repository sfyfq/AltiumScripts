{..............................................................................
    Assign the net name of every selected pad on the active layer to a polygon
    which it overlaps; Make sure that only one polygon covers the center of 
    each pad

    When more than one polygon overlaps with the pad, the system would prompt
	the user to make a selection
    Version 1.0                                                          

    ́Author: Yifeng Qiu @ Lumileds                                                
..............................................................................}

Const ZoomEffect = False;

Procedure MassAttachNetNameToPolygonFromPad;
Var
    Board     : IPCB_Board;
    Prim      : IPCB_Primitive;
    Prim2     : IPCB_Primitive;
    PadObject : IPCB_Primitive;
    Layer     : TLayer;
    x,y,      : TCoord;
    i         : Integer;
    Rect      : TCoordRect;
    Iter_pad  : IPCB_GroupIterator;
    PrimList  : TInterfaceList;
    

Begin
    Pcbserver.PreProcess;

    Try
        Board := PCBServer.GetCurrentPCBBoard;

        If Not Assigned(Board) Then
        Begin
            ShowMessage('The Current Document is not a Altium PCB Document.');
            Exit;
        End;
        ShowMessage('Warning: all the polygon overlapping selected pads will have their net names updated');
        Layer := Board.CurrentLayer;
        PrimList := TInterfaceList.Create;
        for i := 0 to Board.SelectecObjectCount - 1 do
        Begin
            Prim := Board.SelectecObject[i];
            if (Prim.ObjectId = ePadObject) or (Prim.ObjectId = eComponentObject) or (Prim.ObjectId = eViaObject)Then
                PrimList.Add(Prim);
        End;
        
        ResetParameters;
        AddStringParameter('Scope','All');
        RunProcess('PCB:Deselect');
        
        For i := 0 to PrimList.Count - 1 do
        Begin
            Prim := PrimList[i];
            Prim.Selected := True;
			If (i = 0) or (ZoomEffect = True) then
            Begin
				ResetParameters;
				AddStringParameter('Action','Selected');
				RunProcess('PCB:Zoom');
			End;
            If (Prim.ObjectID = ePadObject) or (Prim.ObjectID = eViaObject) then
            Begin
                x := Prim.x;
                y := Prim.y;
                Prim2 := Board.GetObjectAtXYAskUserIfAmbiguous(x,y, MkSet(ePolyObject),
                                                MkSet(Layer),
                                                eEditAction_Select);
                if (Prim.Net <> Nil) and (Prim2 <> Nil) then
                begin
                    //Polygon.selected := True;
                    Prim2.Net := Prim.Net;
                    Prim2.Rebuild;
                end;
            End
            Else if Prim.ObjectID = eComponentObject then
            Begin
                Iter_pad := Prim.GroupIterator_Create;
                Iter_pad.AddFilter_ObjectSet(MkSet(ePadObject));
                PadObject := Iter_pad.FirstPCBObject;
                While (PadObject <> nil) Do
                Begin
                    x := PadObject.x;
                    y := PadObject.y;
                    Prim2 := Board.GetObjectAtXYAskUserIfAmbiguous(x,y, MkSet(ePolyObject),
                                                MkSet(Layer),
                                                eEditAction_Select);
                    if (PadObject.Net <> Nil) and (Prim2 <> Nil) then
                    begin
                        Prim2.Net := PadObject.Net;
                        Prim2.Rebuild;
                    end;
                    PadObject := Iter_pad.NextPCBObject;
                End;
                Prim.GroupIterator_Destroy(Iter_pad);
            End;
            Prim.Selected := False;
       End;

    Finally
        PrimList.Free;
        ResetParameters;
        AddStringParameter('Action','RepourAllPolygons');
        RunProcess('PCB:ChangeObject');
        Client.SendMessage('PCB:Zoom', 'Action=Document', 255, Client.CurrentView);
    End;
	Pcbserver.PostProcess;
End;

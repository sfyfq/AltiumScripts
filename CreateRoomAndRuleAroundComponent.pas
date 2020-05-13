{..............................................................................}
{                                                                              }
{                                                                              }
{         A script for creating rooms and clearance rules around each and 	   }
{		  every selected component               	   						   }
{                                                                              }
{         Yifeng Qiu @ Lumileds                                                }
{         Version 1.0                                                          }
{..............................................................................}


Const
    MarginX 	= 1.0; // Extension of 1mm in the X axis;
    MarginY 	= 0.5; // Extension of 0.5mm in the Y axis;
	Clearance 	= 0.1; // Clearance of 0.1mm

Var
    Board     		: 	IPCB_Board;
    P          		: 	IPCB_ConfinementConstraint;
    RoomCoordRect  	: 	TCoordRect;
    RoomMarginX 	: 	TCoord;
    RoomMarginY 	: 	TCoord;
    Comp     		: 	IPCB_Component;
    CompBoundingBox :	TCoordRect;
	
{..............................................................................}
Function AddRoomClearanceRule(RoomName : TString, Clearance: TCoord) : IPCB_ClearanceConstraint;
Begin
	//Create a new Clearance Rule
	Result := PCBServer.PCBRuleFactory(eRule_Clearance);
	PCBServer.SendMessageToRobots(Result.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
	Result.Name := RoomName + '__ClearanceRule';
	Result.Scope1Expression := 'WithinRoom(''' + RoomName + ''')';
	Result.Scope2Expression := 'WithinRoom(''' + RoomName + ''')';
	Result.Gap := Clearance;
	Board.AddPCBObject(Result);
	PCBServer.SendMessageToRobots(Result.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
End;

Function CreateRoom(RoomCoordRect : TCoordRect, RoomName : TString,  RoomLayer: TLayer) : IPCB_ClearanceConstraint;
Begin
    //Create a new Clearance Rule
    P := PCBServer.PCBRuleFactory(eRule_ConfinementConstraint);
    // Set values
    P.NetScope  := eNetScope_AnyNet;
    P.LayerKind := eRuleLayerKind_SameLayer;
    P.BoundingRect := RoomCoordRect;
    P.ConstraintLayer := RoomLayer;
    P.Kind := eConfineIn;
    P.Name    := RoomName; //Component.Name.Text + '_Room';
    P.Comment := 'Custom room definition (confinement constraint) rule.';
    Board.AddPCBObject(P);
End;


Procedure CreateRoomAndRuleAroundComponent;
Var
    x,y,      		:	TCoord;
    Rotation  		: 	TAngle;
    ComponentName 	: 	TString;
    RoomName 		: 	TString;
    RuleName 		: 	TString;
	CompList		: 	TInterfaceList;
	Prim			:	IPCB_Primitive;
	i				:	Integer;

Begin
    // Parameters
    RoomMarginX := MMsToCoord(MarginX); // define margin around the bounding box of the selected object
    RoomMarginY := MMsToCoord(MarginY); // define margin around the bounding box of the selected object
    Try
        Board := PCBServer.GetCurrentPCBBoard;
        If Not Assigned(Board) Then
        Begin
            ShowMessage('The Current Document is not an Altium PCB Document.');
            Exit;
        End;
		ShowMessage('Warning: we are going to create room constraints around selected components');
		CompList := TInterfaceList.Create;
		for i := 0 to Board.SelectecObjectCount - 1 do
        Begin
            Prim := Board.SelectecObject[i];
            if  (Prim.ObjectId = eComponentObject) Then
                CompList.Add(Prim);
        End;
		PCBServer.PreProcess;
		For i := 0 to CompList.Count - 1 do
		Begin
			Comp := CompList[i];
			If Not Assigned(Comp) Then Exit;    
            // Check if Component Name property exists before extracting the text
            If Comp.Name = Nil Then Exit;
            CompBoundingBox := Comp.BoundingRectangleForSelection;
            RoomCoordRect := TCoordRect;
            RoomCoordRect.X1 := CompBoundingBox.left - RoomMarginX;
            RoomCoordRect.Y1 := CompBoundingBox.bottom - RoomMarginY;
            RoomCoordRect.X2 := CompBoundingBox.right + RoomMarginX;
            RoomCoordRect.Y2 := CompBoundingBox.top + RoomMarginY;
			// Create a rectangular room around the selected component using the boundingbox + margin
            CreateRoom(RoomCoordRect, Comp.Name.Text, Comp.Layer);
            AddRoomClearanceRule(P.Name, MMsToCoord(Clearance));	
		End;
		PCBServer.PostProcess;
    Finally
        Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);
    End;
End;

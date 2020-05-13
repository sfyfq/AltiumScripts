{..............................................................................
   Rotate all text strings on TopOverlay, Bottom Overlay, Mechanical5 and
   Mechanical6 to face upwards for better readability

   Date: December 17, 2018
   Author: Yifeng Qiu @ Lumileds
..............................................................................}

Procedure MassChangeTextRotation;
Var
  Board : IPCB_Board;
  IText : IPCB_Text;
  Iterator : IPCB_SpatialIterator;
  OldCenterX, OldCenterY : TCoord;
  NewCenterX, NewCenterY : TCoord;
  Width, Height: TCoord;
  Rotation : TReal;
  BR : TCoordRect;
Begin
// Retrieve the current board
   Board := PCBServer.GetCurrentPCBBoard;
   If Board = Nil Then Exit;
   BR := Board.BoardOutline.BoundingRectangle;
   Iterator := Board.SpatialIterator_Create;
   Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
   Iterator.AddFilter_LayerSet(MkSet(
   									eTopOverlay,
   									eBottomOverlay,
                                    eMechanical5,
                                    eMechanical6));
   Iterator.AddFilter_Area(BR.Left, BR.Bottom, BR.Right, BR.Top);
   IText := Iterator.FirstPCBObject;

   While (IText <> Nil) Do
   Begin

        if (IText.Rotation < 90) or (IText.Rotation > 270) Then
        Begin
            IText := Iterator.NextPCBObject;
            continue;
        End;

        IText.Selected := True;
        Width := IText.X2Location - IText.X1Location;
        Height := IText.Y2Location - IText.Y1Location;
        Rotation := Degrees2Radians(IText.Rotation);
        If IText.MirrorFlag = False Then
        Begin

        	OldCenterX := IText.XLocation + 0.5*Width*cos(Rotation)-0.5*Height*sin(Rotation);
        	OldCenterY := IText.YLocation + 0.5*Width*sin(Rotation)+0.5*Height*cos(Rotation);
        End
        Else
        Begin
            OldCenterX := IText.XLocation - 0.5*Width*cos(Rotation)-0.5*Height*sin(Rotation);
        	OldCenterY := IText.YLocation - 0.5*Width*sin(Rotation)+0.5*Height*cos(Rotation);
        End;

        Pcbserver.PreProcess;
        PCBServer.SendMessageToRobots(IText.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
        IText.RotateAroundXY(OldCenterX, OldCenterY, 180);


        PCBServer.SendMessageToRobots(IText.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
        Pcbserver.PostProcess;
        IText := Iterator.NextPCBObject;
   End;

   Board.SpatialIterator_Destroy(Iterator);

End;

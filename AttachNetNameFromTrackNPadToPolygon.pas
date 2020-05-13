{..............................................................................}
{ Attach the net name from a track or a pad to a polygon                       }
{                                                                              }
{         The script behaves differently depending on the location where       }
{         the user clicks                                                      }
{         1. if the user clicks at a point where there is a track or a pad     }
{            that overlaps with a polygon, the polygon will take on the        }
{            net name of the pad or the track. A pad has a higher priority     }
{            than a track                                                      }
{         2. if the user clicks at a point where there is only polygon, the    }
{            script will ask the user to click at a track or a pad. Upon       }
{            successful completion of the task, the net name of the pad or     }
{            the track is transferred to the polygon.                          }
{                                                                              }
{         Click on an empty space to end the script                            }
{         Version 2.0                                                          }
{..............................................................................}
{ Author: Yifeng Qiu @ Lumileds												   }
{..............................................................................}

Procedure AttachNetNameFromTrackNPadToPolygon;
Var
    Board     : IPCB_Board;
    Prim     : IPCB_Primitive;
    PadObject : IPCB_Pad;
    Polygon   : IPCB_Polygon;
    Layer     : TLayer;
    x,y,      : TCoord;
    i         : Integer;
    Rect      : TCoordRect;
    Iterator  : IPCB_SpatialIterator;
    FoundTrack: Boolean;
    FoundPad  : Boolean;

Begin
    Pcbserver.PreProcess;

    Try
        Board := PCBServer.GetCurrentPCBBoard;

        If Not Assigned(Board) Then
        Begin
            ShowMessage('The Current Document is not a Altium PCB Document.');
            Exit;
        End;
        Layer := Board.CurrentLayer;

        Repeat
            FoundTrack := False;
            FoundPad := False;
            Board.ChooseLocation(x,y, 'Choose a polygon');
            //ShowMessage('Pad X:' + CoordUnitToString(x, eMM) + ' Pad Y:' + CoordUnitToString(y, eMM));
            Polygon := Board.GetObjectAtXYAskUserIfAmbiguous(x,y, MkSet(ePolyObject),
                                            MkSet(Layer),
                                            eEditAction_Select);

            if Polygon = nil then exit;
            { Define a very small rectangle around the selected point, then find all the
              tracks and pads intersecting this rectangle}


            Iterator := Board.SpatialIterator_Create;
            Iterator.AddFilter_LayerSet(MkSet(Layer));
            Iterator.AddFilter_Area((x-2), (y-2), (x+2), (y+2));
            Iterator.AddFilter_ObjectSet(MkSet(ePadObject, eTrackObject, eArcObject));

            Prim := Iterator.FirstPCBObject;
            while Prim <> nil do
               Begin
                   // if the object is a pad, the pad's net name is used and
                   // the loop stops
                   if (Prim.ObjectID = ePadObject) then
                   Begin
                       FoundPad := True;
                       Polygon.Net := Prim.Net;
                       break;
                   End
                   else if (Prim.ObjectID = eTrackObject) or (Prim.ObjectID = eArcObject) then
                   Begin
                   if FoundTrack = False then
                       Begin
                            FoundTrack := True;
                            Polygon.Net := Prim.Net;
                            
                            // only the first track or arc is used; the loop
                            // continues until the list is depleted or a pad
                            // is found
                       End
                   End;
                   Prim := Iterator.NextPCBObject;
               End;
            Board.SpatialIterator_Destroy(Iterator);

            if (FoundPad = False) and (FoundTrack = False) then
            Begin
                Board.ChooseLocation(x,y, 'Choose a pad, a track or an arc');
                Prim := Board.GetObjectAtXYAskUserIfAmbiguous(x,y,
                                            MkSet(eTrackObject, eArcObject, ePadObject),
                                            MkSet(Layer),
                                            eEditAction_Select);
                if Prim <> nil then
                    Polygon.Net := Prim.Net;
            End;

            Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);


        // click on the board to exit or RMB
        Until (Polygon = Nil);

    Finally
        Pcbserver.PostProcess;
        Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);
    End;
End;

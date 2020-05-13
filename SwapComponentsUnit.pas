{..............................................................................}
{ Summary Swaps two components including rotation                  			   }
{                                                                              }
{         A script to ask the user to select two components then               }
{         have their positions swapped                                         }
{                                                                              }
{         Limitations of this script:                                          }
{         You need to move the cursor away from a component to exit            }
{                                                                              }
{         Yifeng Qiu @ Lumileds                                                }
{         Version 1.0                                                          }
{..............................................................................}

{..............................................................................}
Procedure ChooseAndSwapComponents;
Var
    Board     : IPCB_Board;
    Comp1     : IPCB_Component;
    Comp2     : IPCB_Component;

    x,y,      : TCoord;
    x1, y1    : TCoord;
    Rotation  : TAngle;
Begin
    Pcbserver.PreProcess;

    Try
        Board := PCBServer.GetCurrentPCBBoard;
        If Not Assigned(Board) Then
        Begin
            ShowMessage('The Current Document is not a Altium PCB Document.');
            Exit;
        End;
    
        Repeat
            Board.ChooseLocation(x,y, 'Choose Component1');
            Comp1 := Board.GetObjectAtXYAskUserIfAmbiguous(x,y,MkSet(eComponentObject),AllLayers, eEditAction_Select);
            If Not Assigned(Comp1) Then Exit;

            Board.ChooseLocation(x,y, 'Choose Component2');
            Comp2 := Board.GetObjectAtXYAskUserIfAmbiguous(x,y,MkSet(eComponentObject),AllLayers, eEditAction_Select);
            If Not Assigned(Comp2) Then Exit;
    
            // Check if Component Name property exists before extracting the text
            If Comp1.Name = Nil Then Exit;
            If Comp2.Name = Nil Then Exit;

            // Check if same component selected twice
            If Comp1.Name.Text = Comp2.Name.Text	
			Then
			Begin
				Continue;
			End
			Else		
            Begin
                PCBServer.SendMessageToRobots(Comp1.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);
                PCBServer.SendMessageToRobots(Comp2.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);            // Swap Components

                // swap two components
                x1 := comp1.x;
                y1 := comp1.y;

                comp1.x := comp2.x;
                comp1.y := comp2.y;

                comp2.x  := x1;
                comp2.y  := y1;
								
								Rotation := comp1.Rotation;
								comp1.Rotation := comp2.Rotation;
								comp2.Rotation := Rotation;
                PCBServer.SendMessageToRobots(Comp1.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
                PCBServer.SendMessageToRobots(Comp2.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);

                Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);
             End;

        // click on the board to exit or RMB
        Until (Comp1 = Nil) Or (Comp2 = Nil);

    Finally
        Pcbserver.PostProcess;
        Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);
    End;
End;

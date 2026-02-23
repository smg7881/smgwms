import os
import win32com.client
import time

def convert_to_pdf(folder):
    word = win32com.client.DispatchEx("Word.Application")
    word.Visible = False
    
    # 0 = wdAlertsNone
    word.DisplayAlerts = 0 
    
    try:
        for filename in os.listdir(folder):
            if filename.startswith("~$"):
                continue
            if filename.endswith(".doc") or filename.endswith(".docx"):
                in_file = os.path.join(folder, filename)
                out_file = os.path.join(folder, os.path.splitext(filename)[0] + ".pdf")
                
                if os.path.exists(out_file):
                    print(f"Skipping {filename}")
                    continue
                
                print(f"Converting {filename}...")
                doc = None
                try:
                    # Open(FileName, ConfirmConversions, ReadOnly, AddToRecentFiles)
                    doc = word.Documents.Open(
                        in_file, 
                        ConfirmConversions=False, 
                        ReadOnly=True, 
                        AddToRecentFiles=False
                    )
                    
                    # FileFormat 17 = wdFormatPDF
                    doc.SaveAs(out_file, FileFormat=17)
                except Exception as e:
                    print(f"Failed to convert {filename}: {e}")
                finally:
                    if doc is not None:
                        try:
                            doc.Close(SaveChanges=0)
                        except:
                            pass
    finally:
        try:
            word.Quit(SaveChanges=0)
        except:
            pass
        print("Done.")

if __name__ == "__main__":
    convert_to_pdf(r"D:\_LOGIS\2.오더\2.DS.02.화면설계서")

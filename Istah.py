#!/usr/bin/python3
#encoding: utf-8
import os
from tkinter import *
from tkinter import font
from tkinter import messagebox
from tkinter import filedialog

# Global Var
FONTSIZE='18'
ISTAH_TMP='.temp.is'
ISTAH_SCRIPT=ISTAH_TMP

# Tool func
def load():
    global ISTAH_SCRIPT
    ISTAH_SCRIPT = filedialog.askopenfilename(title='打开文件', filetypes=[('Istah', '*.is *.ish'), ('All Files', '*')])
    print('File Path='+ISTAH_SCRIPT)
    try:
        tmpFile = open(ISTAH_SCRIPT, 'r')
        code = tmpFile.read()
        Text_Code.delete('0.0', END)
        Text_Code.insert('0.0', code)
    except:
        messagebox.showerror('错误', '无法打开此文件!')
    finally:
        tmpFile.close()

def savetmp():
    global ISTAH_SCRIPT, ISTAH_TMP
    code=Text_Code.get('0.0',END)
    try:
        tmpFile = open(ISTAH_TMP, 'w+')
        tmpFile.write(code)
        ISTAH_SCRIPT = ISTAH_TMP
    except:
        messagebox.showerror('错误', '无法打开临时文件!')
    finally:
        tmpFile.close()

def idehelp():
    messagebox.showinfo('帮助', '临时脚本编辑后必须先点击"保存为tmp"再运行！')

def run():
    global ISTAH_SCRIPT
    cmd="lua5.3 ./istah.lua "+ISTAH_SCRIPT
    print('Cmd='+cmd)
    ret=os.popen(cmd).read()
    Text_Shell.delete('0.0', END)
    Text_Shell.insert('0.0', ret)

# Main Entrance
Window = Tk()
Window.title('Istah Poor IDE v0.1 by Kahsolt 2017/1/4')

ToolBar = Frame(Window)
button_run=Button(ToolBar, text="运行" ,command=run, background="red")
button_open=Button(ToolBar, text="打开...", command=load)
button_save=Button(ToolBar, text="保存为tmp", command=savetmp)
button_help=Button(ToolBar, text="帮助", command=idehelp)
button_run.pack(side=LEFT)
button_open.pack(side=LEFT)
button_save.pack(side=LEFT)
button_help.pack(side=RIGHT)
ToolBar.pack(side=TOP, fill=X)

Font=font.Font(font=('Fixdsys', FONTSIZE, font.NORMAL))
Panel = PanedWindow(Window)
Text_Code=Text(Panel,width=40,height=20,font=Font)
Text_Shell=Text(Panel,bg='black',fg='white',width=30,font=Font)
Panel.add(Text_Code)
Panel.add(Text_Shell)
Panel.pack(fill=BOTH, expand=1)

Window.mainloop()

# try to clean tmpfs
try:
    os.remove(ISTAH_TMP)
except:
    pass
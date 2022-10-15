#! /usr/bin/env python
import re
import sys
import chardet
import time

cur_time = time.strftime("%Y/%m/%d", time.localtime())

def delComment( Text ):
    """ removed comment """
    single_line_comment = re.compile(r"//(.*)$", re.MULTILINE)
    multi_line_comment  = re.compile(r"/\*(.*?)\*/",re.DOTALL)
    Text = multi_line_comment.sub('\n',Text)
    Text = single_line_comment.sub('\n',Text)
    return Text

def delBlock( Text ) :
    """ removed task and function block """
    Text = re.sub(r'\Wtask\W[\W\w]*?\Wendtask\W','\n',Text)
    Text = re.sub(r'\Wfunction\W[\W\w]*?\Wendfunction\W','\n',Text)
    return Text

def findName(inText):
    """ find module name and port list"""
    p = re.search(r'([a-zA-Z_][a-zA-Z_0-9]*)\s*',inText)
    mo_Name = p.group(0).strip()
    return mo_Name

def paraDeclare(inText ,portArr) :
    """ find parameter declare """
    pat = r'\s'+ portArr + r'\s[\w\W]*?[;,)]'
    ParaList = re.findall(pat ,inText)

    return ParaList

def portDeclare(inText ,portArr) :
    """find port declare, Syntax:
       input [ net_type ] [ signed ] [ range ] list_of_port_identifiers

       return list as : (port, [range])
    """
    port_definition = re.compile(
        r'\b' + portArr +
        r''' (\s+(wire|reg)\s+)* (\s*signed\s+)*  (\s*\[.*?:.*?\]\s*)*
        (?P<port_list>.*?)
        (?= \binput\b | \boutput\b | \binout\b | ; | \) )
        ''',
        re.VERBOSE|re.MULTILINE|re.DOTALL
    )

    pList = port_definition.findall(inText)

    t = []
    for ls in pList:
        if len(ls) >=2  :
            t = t+ portDic(ls[-2:])
    return t

def portDic(port) :
    """delet as : input a =c &d;
        return list as : (port, [range])
    """
    pRe = re.compile(r'(.*?)\s*=.*', re.DOTALL)

    pRange = port[0]
    pList  = port[1].split(',')
    pList  = [ i.strip() for i in pList if i.strip() !='' ]
    pList  = [(pRe.sub(r'\1', p), pRange.strip() ) for p in pList ]

    return pList

def formatPort(AllPortList,isPortRange =1) :
    PortList = AllPortList[0] + AllPortList[1] + AllPortList[2]

    str =''
    if PortList !=[] :
        l1 = max([len(i[0]) for i in PortList])+2
        l2 = max([len(i[1]) for i in PortList])
        l3 = max(24, l1)

        strList = []
        for pl in AllPortList :
            if pl  != [] :
                str = ',\n'.join( [' '*4+'.'+ i[0].ljust(l3)
                                  + '( '+ (i[0].ljust(l1 )+i[1].ljust(l2))
                                  + ' )' for i in pl ] )
                strList = strList + [ str ]

        str = ',\n\n'.join(strList)

    return str

def formatDeclare(PortList,portArr, initial = "" ):
    str =''
    if initial !="" :
        initial = " = " + initial

    if PortList!=[] :
        str = '\n'.join( [ portArr.ljust(4) +'  '+(i[1]+min(len(i[1]),1)*'  '
                           +i[0]).ljust(36)+ initial + ' ;' for i in PortList])
    return str

def formatPara(ParaList) :
    paraDec = ''
    paraDef = ''
    if ParaList !=[]:
        s = '\n'.join( ParaList)
        pat = r'([a-zA-Z_][a-zA-Z_0-9]*)\s*=\s*([\w\W]*?)\s*[;,)]'
        p = re.findall(pat,s)

        l1 = max([len(i[0] ) for i in p])
        l2 = max([len(i[1] ) for i in p])
        paraDec = '\n'.join( ['parameter %s = %s;'
                             %(i[0].ljust(l1 +1),i[1].ljust(l2 ))
                             for i in p])
        paraDef =  '\n#(\n' +',\n'.join( ['    .'+ i[0].ljust(l1 +1)
                    + '( '+ i[0].ljust(l1 )+' )' for i in p])+ '\n)\n'
    else:
        l1 = 6
        l2 = 2
    preDec = '\n'.join( ['parameter %s = %s;\n'
                             %('PERIOD'.ljust(l1 +1), '10'.ljust(l2 ))])
    paraDec = preDec + paraDec
    return paraDec,paraDef

def writeTestBench(input_file):
    """ write testbench to file """
    with open(input_file, 'rb') as f:
        f_info =  chardet.detect(f.read())
    with open(input_file) as inFile:
        inText  = inFile.read()

    # removed comment,task,function
    inText = delComment(inText)
    inText = delBlock  (inText)

    # moduel ... endmodule  #
    moPos_begin = re.search(r'(\b|^)module\b', inText ).end()
    moPos_end   = re.search(r'\bendmodule\b', inText ).start()
    inText = inText[moPos_begin:moPos_end]

    name  = findName(inText)
    paraList = paraDeclare(inText,'parameter')
    paraDec , paraDef = formatPara(paraList)

    ioPadAttr = [ 'input','output','inout']
    input  =  portDeclare(inText,ioPadAttr[0])
    output =  portDeclare(inText,ioPadAttr[1])
    inout  =  portDeclare(inText,ioPadAttr[2])

    portList = formatPort( [input , output , inout] )
    input  = formatDeclare(input ,'reg', '0' )
    output = formatDeclare(output ,'wire')
    inout  = formatDeclare(inout ,'wire')

    # write testbench file
    tb_module_name = name + "_tb"
    write_str = ""
    Header ='''//*****************************************************************************
//COPYRIGHT(c) South China University Of Techonology
//
'''
    write_str += Header
    write_str += "//Module name  :" + tb_module_name + "\n"
    write_str += "//File name    :" + tb_module_name + ".v\n"
    write_str += "//\n"
    write_str += "//Author       :TANG\n"
    write_str += "//Email        :tangziming@whut.edu.cn\n"
    write_str += "//Date         :" + cur_time + "\n"
    Tail = '''
//Version      :1.0
/*Abstract

*/
//*****************************************************************************
'''
    write_str += Tail + "\n"

    write_str += "`timescale  1ns / 1ps\n\n"
    write_str += "module " + tb_module_name + ";\n\n"
    # module_parameter_port_list
    if(paraDec!=''):
        write_str += "// " + name + " Parameters\n" + paraDec + "\n\n"

    # list_of_port_declarations
    write_str += "// " + name + " Inputs\n" + input + "\n\n"
    write_str += "// " + name + " Outputs\n" + output + "\n\n"
    if(inout!=''):
        write_str += "// " + name + " Bidirs\n" + inout + "\n\n"
    # fsdb
    fsdb = '''
//dump fsbl
initial begin
    $fsdbDumpfile("waveform.fsdb");
    $fsdbDumpvars(0);
end'''
    # clock
    clk = '''
//Clock generate
initial
begin
    forever #(PERIOD/2)  clk=~clk;
end'''
    # reset
    rst = '''
//Reset generate
initial
begin
    #(PERIOD*2) rst_n  =  1;
end
'''
    write_str +=fsdb + "\n" + clk + "\n" + rst

    # print operation
    operation = '''
//operations
initial
begin

    $finish;
end
'''
    write_str += operation + "\n"

    # UUT
    write_str += "//Test top module\n" + name + " " + paraDef + "u_" + name + "\n(\n" +  portList + "\n);\n\n"

    write_str += "endmodule\n"

    outfile_name = "../tb/" + tb_module_name + ".v"
    fo = open(outfile_name, "w")
    fo.write(write_str)
    fo.close()

if __name__ == '__main__':
    writeTestBench(sys.argv[1])

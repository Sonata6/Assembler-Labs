;sorting words by word length

.model tiny
.code
org 100h
.startup
     
     
output macro str
    mov dx, offset str
    mov ah, 9
    int 21h
endm 

   
input macro str
    mov dx, offset str
    mov ah, 0ah
    int 21h
endm          


endOfString macro
    mov ah, 02h
    mov dl, 0ah
    int 21h
    mov dl, 0dh
    int 21h
endm 


changeSpace macro str, StrLenght, NumOfWords
    mov si, 1                    ;si - indexator
    mov ah, 02h
    mov cx, StrLenght            ;cx - counter
    mov bl, 0
    
    changeSpaces:
    inc si
    cmp str[si], 24h           ;todo
    cmp str[si], 20h
    je ifSpace
    inc bl                       ;bl - lenght of word
    jmp notSpace
    
    ifSpace:
    inc NumOfWords                     
    mov di, si                   ;di - for change last space
    sub di, bx                   ;on lenght of word
    sub di, 1
    add bl, 13            ;add to avoid ascii bugs
    mov str[di], bl
    xor bl, bl
    
    notSpace:
    loop changeSpaces
    inc NumOfWords
    mov di, si
    sub di, bx
    add bl, 11           ;!!!!!!!!!!!!
    mov str[di], bl
endm 


search macro str, tmp, strlen   ; find the least word in the string
    xor si, si
    xor bx, bx
    mov tmp, si                 ;bx - lenght of word
    mov dl, 1                            
    mov bl, str[1]
    sub bl, 13      ;add to avoid ascii bugs
    mov tmp, bx
    mov si, 1 
    
    cycle:
    add si, bx
    inc si
    cmp si, strlen        
    jae endOfAlg         
    mov bl, str[si]
    sub bl, 13
    cmp tmp, bx
    jb cycle
    mov tmp, bx
    mov dx, si            ;dx - start point of the least word
    jmp cycle
    
    itsnotabug:
    endOfAlg:
endm


writetoout macro tmp, strOutput  ;Write least word to strOutput
    mov cx, tmp
    xor dh, dh
    mov si, dx
    wrap:
    inc si
    mov dh, str[si]
    mov strOutput[di], dh
    inc di
    loop wrap
    mov strOutput[di], 20h
    inc di
endm


eraseword macro tmp, strLenght
    xor dh, dh     
    mov si, dx    ;dx - place of word
    mov cx, strLenght
    sub cx, dx
    sub cx, tmp
    inc tmp
    
    cycle1:
    add si, tmp
    mov dh, str[si]      ;ax - buffer 
    sub si, tmp
    mov  str[si], dh
    inc si
    loop cycle1
    mov cx, tmp
    
    decr:
    dec strLenght
    loop decr
endm



;------------- begin of main
output msg1

input str

endOfString

output msg2
;-----------------------
mov si, 1
mov ah, 02h
sizeL:
inc si
cmp str[si], 24h
jne sizeL 
mov StrLenght, si
sub StrLenght, 1
mov cx, StrLenght
;-----------------------  
xor si, si
xor di, di
mov dl, 20h
cmp str[2], dl
jne endCheck
mov char, str[si]


endCheck:

changeSpace str, StrLenght, NumOfWords
endOfString
xor di, di
lastcycle:
dec NumOfWords
search str, tmp, StrLenght

writetoout tmp, strOutput
eraseword tmp, strLenght
    
cmp NumOfWords, 0
jne lastcycle

output strOutput

ret



msg1: db "Input string what you need to sort: ",0Dh,0Ah,24h 
msg2: db "Sorted string: ",0Dh,0Ah,24h
str db 255,255,255 dup ("$")
strOutput db 255,255,255 dup ("$")
StrLenght dw 1
NumOfWords dw 0 
tmp dw 1
char dw 0
end
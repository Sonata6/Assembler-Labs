.model small 
.stack 100h 
.data  

arr_size             equ 30
minMax_size          equ 2
byte_size            equ arr_size * 2

output_last_ind     equ 5
buffer              dw 255, 256 dup (?) 

;min                 dw minMax_size dup(0)        
;max                 dw minMax_size dup(0)
;quantity            dw minMax_size dup('$')
sizeFromUser        dw minMax_size dup('$')

overflow_message    db "number is too large", 0Dh, 0Ah, '$'
error_message       db "error", 0Dh, 0Ah, '$'
array              dw  arr_size dup (0000h)
neg_one             dw 0FFFFh
ten                 dw 000Ah 


exception_output    db "-32768   ", '$'
output_buf          db "         ", '$'
overflow_mult_mess  db "overflow ", '$'
result_message      db "result:", 0Dh, 0Ah, '$'
     
input_message    db "Enter length of array: ", '$' 
message0    db "Array was empty", 0Ah, 0Dh, '$'    
message1    db "The most popular number in array: ",'$'
;message2    db "Enter maximal value of range: ",'$'
message3    db "Enter elements of array: ",0Ah, 0Dh, '$' 
;message4    db "Quantity of numbers in your range[",'$' 
;messSemiColon   db ';','$'
;messBracket db ']','$' 
;messColon   db ": ",'$' 
tmp dw 1
popular dw 1
popularnum dw 1
message5    db "Your array: $" 
errmsg      db 0Ah, 0Dh, "You must enter number: $" 
enter       db 0Ah, 0Dh, '$'
            
           
  
             

.code 
;+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_
  
putch macro symb
    push ax
    push dx
    mov ah, 02h
    mov dl, symb
    int 21h
    pop dx
    pop ax
endm

println macro message
    push dx
    push ax   
    mov ah, 09h 
    mov dx, offset message
    int 21h
    pop ax
    pop dx
endm

printint proc; ax - value to print
    ; uses bx, ax, dx, cx, di, si
    push ax
    push bx
    push dx
    push cx
    push di
    push si
    mov di, output_last_ind
    mov si, 0
    mov cx, 0Ah
    mov bx, ax
    and bx, 1000000000000000b
    jz positive_output; bx is free now
    cmp ax, 8000h
    je negative_exception
    mov si, 1
    imul neg_one
positive_output:
        xor dx, dx
        div cx
        add dx, '0'
        mov output_buf[di], dl
        dec di
        cmp ax, 0
    je can_print
    jmp positive_output
can_print:
    cmp si, 0
    je printing
    mov output_buf[di], '-'
printing:
    mov ah, 09h
    mov dx, offset output_buf
    int 21h    
    mov di, offset output_buf
    mov cx, 8
    mov al, ' '
    rep stosb
    dec di
    jmp printint_end
negative_exception:
    println negative_exception
    jmp printint_end
printint_end:
    pop si
    pop di
    pop cx
    pop dx
    pop bx
    pop ax
    ret
endp
  
  
input_num proc; ax - result number, cx - error code
    push dx
    push bx
    push di
    push si
    mov dx, offset buffer
    mov ah, 0Ah
    int 21h
    mov ah, 02h    ;output dl
    mov dl, 0Dh    ;who is cret
    int 21h
    mov dl, 0Ah    ;who is newl
    int 21h

    xor si, si
    mov di, offset buffer
    add di, 2
    ;*********
    mov cx, 255
    mov al, ' '
    repe scasb   ;compare ES:DI with AX while cx!=0  or while ZF==0
    dec di

    call check_if_legal
    cmp cx, 1
    je other_error

    mov cx, 10
    ;********* 
    cmp byte ptr [di], '-'
    jne positive_input
    mov si, 1
    inc di
positive_input:
    cmp byte ptr [di], '0'
    jb other_error
    cmp byte ptr [di], '9'
    ja other_error
input_is_legal:
    xor ax, ax
    xor bh, bh
    mov cx, 10
parsing_string_loop:
    mov bl, [di]
    cmp bl, '0'
    jb succes
    cmp bl, '9'
    ja succes
    sub bl, '0'
    mul cx
    add ax, bx
    mov bx, ax
    and bx, 8000h
    jnz register_overflow
    inc di
    jmp parsing_string_loop
register_overflow:
    println overflow_message
    mov cx, 1
    jmp input_num_end
other_error:
    println error_message
    mov cx, 1
    jmp input_num_end
succes:
    mov cx, 0
    cmp si, 1
    jne input_num_end
    imul neg_one
    jmp input_num_end
input_num_end:
    pop si
    pop di
    pop bx
    pop dx
    ret
endp

input_array proc; uses cx, ax, si
    push cx
    push ax
    push si
    xor si, si
    
   hereWeGoAgain: 
      println input_message         ;Enter length of array
    call input_num     ;input buffer. Value returned in ax 
    cmp ax,0
    jg goAhead1
    println message0
    jmp terminate 
    goAhead1:
    cmp ax,30
    jl goAhead2
    mov ax,30
    goAhead2:
        
    mov cx,ax
    mov sizeFromUser[0],ax  
    
    println message3
    
    enteringArray: 
     push cx           
    input_array_loop:
        call input_num 
        call comparator
        cmp cx, 1           ;if error input again
    je input_array_loop
        mov array[si], ax    
        add si, 2     
        pop cx
    loop enteringArray

    pop si
    pop ax
    pop cx
    ret
endp 
  
print_array proc; uses ax, di, cx, dx
   
   
    push ax
    push di
    push cx
    push dx
 
    xor di, di
  
    push cx
    push di    
    mov cx, sizeFromUser[0]
    print_arr:
        mov ax, array[di]
        call printint
        add di, 2
    loop print_arr



    pop di
    pop cx 
    pop dx
    pop cx
    pop di
    pop ax
    ret
endp  

find_popular macro 
    push ax
    push di
    push cx
    push dx 
    xor di, di  
    push cx
    push di
    xor ax, ax
    push si
    xor si, si
    mov popular, ax 
       
    mov cx, sizeFromUser[0]
    findNumExternal:
    mov bx, array[si]
    xor di, di
    xor ax, ax
    mov tmp, di
    findNumInternal:
        inc ax
        mov dx, array[di]
        add di, 2
        cmp dx, bx
        jne notequal
        inc tmp
        push dx
        mov dx, tmp
        cmp dx, popular
        jbe nothing
        mov popular, dx
        mov popularnum, bx
        pop dx
        nothing:
        notequal:
        cmp ax, sizeFromUser[0]
        jb findNumInternal
        add si, 2
    loop findNumExternal
    
    println message1
    mov ax, popularnum
    call printint
    pop di
    pop cx 
    pop dx
    pop cx
    pop di
    pop ax
    
endm    

     
     
check_if_legal proc; di - first, cx - result
    push di
    mov cx, 0
    cmp byte ptr [di], '-'    ;access to byte
    inc di

check_if_legal_loop:
        cmp byte ptr [di], 0Dh    ;if enf of string
    je check_if_legal_end
        cmp byte ptr [di], '0'    ;if [di]<'0' 
    jb check_if_legal_fail
        cmp byte ptr [di], '9'    ;if [di]>'9'
    ja check_if_legal_fail
        inc di
    jmp check_if_legal_loop        

check_if_legal_fail:
    mov cx, 1
check_if_legal_end:
    pop di
    ret
endp  

comparator proc 
   push ax
   push dx   
  
  ; mov dx,min   
  ; cmp ax,min ;cmp for ax (ms[si+2*dx]) and di (min)
   jl gg
     
 ;  mov dx,max   
   ;cmp ax,max 
   jg gg
   
   inc bx
   gg:   
   pop dx
   pop ax
  
   cmp cx,0h    
   ret
comparator endp 


start:
    mov ax, @data
    mov ds, ax
    mov es, ax                  
  
    continue:     
    xor bx,bx   
    
                 
    call input_array    

    mov ah, 02h
    mov dl, 0Dh
    int 21h
    mov dl, 0Ah
    int 21h
    
                          
    println message5   ;Your array
    println enter                     
    
    call print_array
    println enter
    find_popular
    

terminate:
    mov ax, 4C00h
    int 21h
end start  


      
    


    

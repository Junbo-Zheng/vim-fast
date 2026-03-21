" this file is for highlight color
" update by chenxuan 2023-01-09 11:09:23

" 支持: #RGB/#RRGGBB、rgb(r,g,b)、rgba(r,g,b,a)
let s:regex='\v(#[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?|rgba?\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}(\s*,\s*[01](\.\d+)?)?\s*\))'
let b:hl_able=0
let b:hl_num=0
let b:hl_dict={}
let b:buf_nr=-1

func! s:Clamp255(n) abort
	let l:v=str2nr(a:n)
	if l:v<0
		return 0
	elseif l:v>255
		return 255
	endif
	return l:v
endfunc

func! s:NormalizeColor(str) abort
	" #RGB
	if a:str =~# '\v^#[0-9A-Fa-f]{3}$'
		let l:r=strpart(a:str,1,1)
		let l:g=strpart(a:str,2,1)
		let l:b=strpart(a:str,3,1)
		return '#'.toupper(l:r.l:r.l:g.l:g.l:b.l:b)
	endif
	" #RRGGBB
	if a:str =~# '\v^#[0-9A-Fa-f]{6}$'
		return '#'.toupper(strpart(a:str,1,6))
	endif

	" rgb()/rgba() -> #RRGGBB (alpha 暂忽略，仅取 rgb)
	let l:m=matchlist(a:str,'\v^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(\s*,\s*[01](\.\d+)?)?\s*\)$')
	if len(l:m)>0 && l:m[0] !=# ''
		let l:r=s:Clamp255(l:m[1])
		let l:g=s:Clamp255(l:m[2])
		let l:b=s:Clamp255(l:m[3])
		return printf('#%02X%02X%02X',l:r,l:g,l:b)
	endif
	return ''
endfunc

func! s:HlDefine() abort
	let list=getbufline("%",1,"$")
	if !exists("b:hl_dict")||!exists("b:hl_num")
		let b:hl_num=0
		let b:hl_dict={}
	endif
	let line=1
	for now in list
		let match=matchstrpos(now,s:regex)
		while match[0]!=""
			let str=match[0]
			let bg=s:NormalizeColor(str)
			if bg==#''
				let match=matchstrpos(now,s:regex,match[2]+1)
				continue
			endif

			if !has_key(b:hl_dict,bg)
				let hl_flag=b:hl_num
				let guifg="#000000"
				if bg==guifg
					let guifg="#FFFFFF"
				endif
				exec ":highlight HlColor".b:hl_num.b:buf_nr." guibg=".bg." guifg=".guifg
				let b:hl_dict[bg]={"hl_num": b:hl_num,"hl_arr":[],"raw_dict":{}}
				let b:hl_num+=1
			endif

			let hl_flag=b:hl_dict[bg]["hl_num"]
			if !has_key(b:hl_dict[bg]["raw_dict"],str)
				let m=matchadd("HlColor".hl_flag.b:buf_nr,'\V'.str)
				call add(b:hl_dict[bg]["hl_arr"],m)
				let b:hl_dict[bg]["raw_dict"][str]=1
			endif
			let match=matchstrpos(now,s:regex,match[2]+1)
		endwhile
		let line+=1
	endfor
endfunc

func! highlightcolor#Able() abort
	if exists("b:hl_able")&&b:hl_able
		return
	endif
	let b:hl_able=1
	let b:buf_nr=bufnr()
	call s:HlDefine()
endfunc


func! highlightcolor#DisAble()
	if !exists("b:hl_able")||b:hl_able==0
		return
	endif

	for [key,val] in items(b:hl_dict)
		let m="HlColor".val["hl_num"].b:buf_nr
		for temp in val["hl_arr"]
			call matchdelete(temp)
		endfor
		highlight clear m
	endfor
	let b:hl_dict={}
	let b:hl_able=0
endfunc

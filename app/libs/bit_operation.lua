--[[ 
   位运算工具类
]]--

local f_bit={}

function f_bit:new()

   local instance = {}
   local m_data32 = {}
   
	for i = 1,32 do
		m_data32[i] = 2^(32-i)
   end
    
   instance.m_data32=m_data32
   setmetatable(instance, { __index = self})
   return instance
end

-- 10进制转2进制
function f_bit:d2b(arg)
	local tr= {}
	for i = 1,32 do
		if arg >= self.m_data32[i] then
			tr[i] = 1
			arg = arg- self.m_data32[i]
		else
			tr[i] = 0
		end
	end
	return tr
end


-- 2进制转10进制
function f_bit:b2d(arg)
	local nr = 0 
	for i = 1,32 do
		if arg[i] == 1 then
			nr = nr+2^(32-i)
		end
	end
	
	return nr
end

-- 位与
function  f_bit:_and(a,b)  
   local op1=self:d2b(a)  
   local op2=self:d2b(b)  
   local r={}  
      
   for i=1,32 do  
     if op1[i]==1 and op2[i]==1  then  
         r[i]=1  
     else  
         r[i]=0  
     end  
   end  
   return self:b2d(r)  
end 

-- 位或
function f_bit:_or(a,b)  
   local op1=self:d2b(a)  
   local op2=self:d2b(b)  
   local r={}  
    
   for i=1,32 do  
     if op1[i]==1 or op2[i]==1 then  
        r[i]=1  
     else  
        r[i]=0  
     end  
   end  
   return  self:b2d(r)  
end   

-- 右移
function f_bit:_rshift(a,n)  
   local   op1=self:d2b(a)  
   local   r=self:d2b(0)  
      
   if n < 32 and n > 0 then  
      for i=1,n do  
         for i=31,1,-1 do  
            op1[i+1]=op1[i]  
         end  
         op1[1]=0  
      end  
      r=op1  
   end  
   return  self:b2d(r)  
end

-- 左移
function f_bit:_lshift(a,n)  
   local op1=self:d2b(a)  
   local r=self:d2b(0)  
     
   if n < 32 and n > 0 then  
      for i=1,n   do  
        for i=1,31 do  
            op1[i]=op1[i+1]  
        end  
        op1[32]=0  
      end  
      r=op1  
   end  
   return  self:b2d(r)  
end   


local function  index_char(ch)
   local str="0123456789ABCDEF"

   local num=string.find(str,ch,1) -1
   
   return num
end

-- 16进制字符串转byte数组
 function  f_bit:str_to_byte(str)

   if str==nil or str=="" then
       return nil
   end
   
   local upstr=string.upper( str )

   local len=#str/2
   
   local tab=table.new(64, 0) 

   for i=1,string.len(upstr) do

       table.insert(tab,string.sub(upstr,i,i))

   end

   local tab_b={}

   local bit=bit_opera:new()
   
   for i=0,len-1,1 do 
       
       local p=i*2
       p=p+1

       local a=index_char(tab[p])

       a=bit:_lshift(a,4)

       local b=index_char(tab[p+1])
   
       local num=bit:_or(a,b)

       --做类似于java的转换
       if num>127 then
           num=num-256
       end
       
       table.insert(tab_b,num)
       
   end

   return tab_b
   
end

return f_bit
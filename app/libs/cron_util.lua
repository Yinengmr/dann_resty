-- 定時任務業務層
local cjson = require("cjson")
local utils  = require("app.libs.utils")
local ngx_log=ngx.log
local type=type
local table=table
local tonumber=tonumber
local string=string
local osdate=os.date
local ostime=os.time
local type=type

local _M = {}

--获取当前的时间戳，和时间戳转换成的字符串
local function tamp_time()
    local tab={}
    tab.year=tonumber(osdate("%Y"))
    tab.month=tonumber(osdate("%m"))
    tab.day=tonumber(osdate("%d"))
    return tab
end

local function split_s(flag,str)
    local tab={}
    string.gsub(str, '[^'..flag..']+', function(w)
            table.insert(tab, w)
    end)
    return tab
end

--通过传过来的字符串，获取相对应的日期封装的tab
local function get_time_tab(str)
   
    local s=split_s("+",str)
    local num=tonumber(s[2])
    local n_t=ostime()
    local a_t=n_t+num*3600*24

    local tab={}
    tab.year=osdate("%Y",a_t)
    tab.month=osdate("%m",a_t)
    tab.day=osdate("%d",a_t)

    return tab
end

--把linux中对于星期几的设置改成lua中设置的星期几 0-7 0和7代表星期天，1-6代表周一到周六
-- 0 1 2 3 4 5 6 7
-- 0 1 2 3 4 5 6 7
-- 把lua中对于日期的设置转成linux中的数据
local function lua_wk_linux(wk)
   if wk==0 then
        return 7
   else
      return wk
   end
end

--通过传过来的星期几，转成相对应需要加或减的天数，并转成相对应的日期，返回当前的时间戳和转换后对应的日期
local function get_tag_week(wk)
    local now_wk=tonumber(osdate("%w"))
    ngx_log(ngx.ERR,"ngx_wk for lua:",now_wk)
    now_wk=lua_wk_linux(now_wk)
    -- ngx_log(ngx.ERR,"ngx_wk:",now_wk)
    if wk==0 then
        wk=7
    end

    local tag_str
    local num

    if wk>=now_wk then
        num=wk-now_wk
        tag_str='d+'..num
    else
        num=now_wk-wk
        tag_str='d-'..num
    end

    local tab=get_time_tab(tag_str)
    return tab
end

--传入相对应的分割标识符和需要分割的字符串，转成相对应的tab数组或者数字并返回
--需要进行改进，由于对于格式定义的需求，只允许用，号和-的形式去进行操作
local function split_str(str)
    local a=string.find(str,",")
    local b=string.find(str,'-')

    if a and b then
        return nil
    elseif a~=nil and b==nil then
        --为,号
        local tab={}
        string.gsub(str, '[^,]+', function(w)
            local num= tonumber(w)
            if num==nil then
                tab=nil
                return
            else
                table.insert(tab, num)
            end  
        end)
        return tab

    elseif a==nil and b~=nil then
        --为-号
        local tab={}
        string.gsub(str, '[^-]+', function(w)
            local num= tonumber(w)
            if num==nil then
                tab=nil
                return
            else
                table.insert(tab, num)
            end  
        end)

        if tab~=nil and #tab==2 then
            local a=tab[1]
            local b=tab[2]
            if b<a then
                return nil
            end
            local c=a
            while c<b-1 do
                c=c+1
                table.insert(tab,c)
            end
            return tab
        else
            return nil
        end
        
    else
        local num=tonumber(str)
        if num==nil then
            return nil
        else
            local r_tab={}
            table.insert(r_tab, num)
            return r_tab
        end
    end

end

-- min hour * * week   指的是星期几操作(参数为0或7)，周日可以是0也可以是7,在这里，需要对日期进行修改
-- 通过传进来的参数，返回相互对应的时间戳的数组
local function min_hour_week(min_tab,hr_tab,wk_tab)
    local tab={}
    local tt=''
    for k,v in pairs(wk_tab) do
        --获取对应星期几的年，月，日
        local f_tab=get_tag_week(v)
    -- ngx_log(ngx.ERR,"f_tab:",cjson.encode(f_tab))
        for k_t,v_t in pairs(hr_tab) do 
            f_tab["hour"]=v_t

            for k_th,v_th in pairs(min_tab) do 
                f_tab["min"]=v_th
                tt=ostime(f_tab)
                table.insert(tab,tt)
            end

        end

    end
    ngx_log(ngx.ERR,"test time tab:",cjson.encode(tab))
    return tab
end

--指的是具体的哪个月的几号
local function min_hour_day_mon(min_tab,hr_tab,day_tab,mon_tab)
    local tab={}
    local t_tab={}
    tab.year=osdate("%Y")
    local tt=''

    for k,v in pairs(mon_tab) do
        local f_tab=tab
        f_tab.month=v

        for k_t,v_t in pairs(day_tab) do
            f_tab.day=v_t

            for k_th,v_th in pairs(hr_tab) do
                f_tab.hour=v_th
                
                for k_f,v_f in pairs(min_tab) do
                    f_tab.min=v_f
                    tt=ostime(f_tab)
                    table.insert(t_tab,tt)
                end

            end

        end

    end

    return t_tab
end

-- min hour day * * 指的是每个月的某几号操作
local function min_hour_day(min_tab,hr_tab,day_tab)
    local tab={}
    local t_tab={}
    tab.year=osdate("%Y")
    tab.month=osdate("%m")
    local tt=''

    for k,v in pairs(day_tab) do
        local f_tab=tab
        f_tab.day=v
        for k_t,v_t in pairs(hr_tab) do
            f_tab.hour=v_t

            for k_th,v_th in pairs(min_tab) do
                f_tab.min=v_th
                tt=ostime(f_tab)
                table.insert(t_tab,tt)
            end
        end

    end
    
    return t_tab
end

-- min hour * * * 指的是每天的几点操作
local function min_hour(min_tab,hr_tab)
    local tab=tamp_time()
    local t_tab={}
    local tt=''

    for k,v in pairs(hr_tab) do
        local f_tab=tab
        f_tab.hour=v

        for k_t,v_t in pairs(min_tab) do 
            f_tab.min=v_t
            tt=ostime(f_tab)
            table.insert(t_tab,tt)
        end
      
    end
    
    return t_tab
   
end

-- 转换分钟
local function change_min(min_tab)
    local tab=tamp_time()
    tab.hour=0
    local t_tab={}
    local tt=''

    for k,v in pairs(min_tab) do
        local f_tab=tab
        f_tab.min=v
        tt=ostime(f_tab)
        table.insert(t_tab,tt)
    end
    
    return t_tab
end

-- 通过传进来的时间戳，获取当月的天数
local function month_days(tt)
    local year=osdate("%Y",tt)
    local month=osdate("%m",tt)
    if(year%4 == 0 and year%100 ~= 0) then
        local month = tonumber(month)
        if(month == 2) then
           return 28
        end
    else								     
        local month = tonumber(month)
        if(month == 2) then
            return 29
        end
    end
     
    monthMax = {1,3,5,7,8,10,12}		
    months = {4,6,9,11}					
    for i,m in ipairs(monthMax)do		
        local lable = tonumber(month)	
        if m == lable then			
           return 31
        end
    end
     
    for i,m in ipairs(months)do		
        local lable = tonumber(month)
        if m == lable then
            return 30
        end
    end
 
end

-- 通过传过来的tab获取相对于现在的时间到目标执行的时间之间的时间戳
local function parse_cron_tab(tab,now)
    -- 对于表达式的分类,目前分为5大类
    local time_tab={}
    local timestamp
    -- min * * * *，
    -- */5 * * * *
    -- 10,20,30 * * * * (最大)
    if tab["min"]~="*" and tab["hour"]=="*" and tab["day"]=="*" and tab["month"]=="*" and tab["week"]=="*" then
        local min=tab["min"]
        local f_res=string.find(min,"/")
        local exec_time

        if f_res~=nil then
            string.gsub(min, '[^/]+', function(w) table.insert(time_tab, w) end )
            local time=time_tab[#time_tab]
            exec_time=tonumber(time)
            if exec_time~=nil then
                timestamp=exec_time*60
                return 1,timestamp
            else
                return nil
            end
    
        else
            --每天早上过多少分钟进行操作，范围在0到60,可以是20,30,40,需要完善
            local min_str=tab["min"]
            local min_tab=split_str(min_str)
            table.sort(min_tab)

            ngx_log(ngx.ERR,"the change tab is:",cjson.encode(min_tab))

            if min_tab==nil then
                return nil
            end
            
            -- 获取转换后的时间戳
            local time_tab=change_min(min_tab)
            
            local tt
            if now~=nil then
                tt=now
            else
                tt=ostime()
            end

            table.insert(time_tab,tt)
            table.sort(time_tab)
    
            local f_num
            for k,v in pairs(time_tab) do
                if tt==v then
                    f_num=k
                    break
                end 
            end

        ngx_log(ngx.ERR,"time_tab is:",cjson.encode(time_tab))

            if f_num~=#time_tab then

                if time_tab[f_num]==time_tab[f_num+1] then
                    if time_tab[f_num]==time_tab[#time_tab] then
                       local min=min_tab[1]
                       local tab=get_time_tab("d+1") 
                       tab.hour=0
                       tab.min=min
                       local tf=ostime(tab)
                       return 1,tf-tt
                    else
                        --返回下一个时间的时间戳
                        return 1,time_tab[f_num+2]-tt
    
                    end
                else
                     --返回下一个时间的时间戳
                     return 1,time_tab[f_num+1]-tt
                end
            
            else
                local min=min_tab[1]
                local tab=get_time_tab("d+1") 
                tab.hour=0
                tab.min=min
                local tf=ostime(tab)
                return 1,tf-tt
            end

        end

    -- min hour * * * 或者* hour * * *
    -- 20,30 5,6 * * * (最大限度)
    elseif tab["min"]~="*" and  tab["hour"]~="*" and tab["day"]=="*" and tab["month"]=="*" and tab["week"]=="*" then
        local hr_str=tab["hour"]
        local min_str=tab["min"]
        local hr_tab=split_str(hr_str)
        local min_tab=split_str(min_str)
        table.sort(hr_tab)
        table.sort(min_tab)

        if hr_tab==nil or min_tab==nil then
            return nil
        end
        
        --获取转换后的时间戳
        local time_tab=min_hour(min_tab,hr_tab)

        local tt
        if now~=nil then
            tt=now
        else
            tt=ostime()
        end
       
        table.insert(time_tab,tt)
        table.sort(time_tab)

        local f_num
        for k,v in pairs(time_tab) do
            if tt==v then
                f_num=k
                break
            end 
        end

        ngx_log(ngx.ERR,"time_tab is:",cjson.encode(time_tab))

        if f_num~=#time_tab then

            if time_tab[f_num]==time_tab[f_num+1] then
                if time_tab[f_num]==time_tab[#time_tab] then
                    local hour=hr_tab[1]
                    local min=min_tab[1]
                    local tab=get_time_tab("d+1")
                    tab.hour=hour
                    tab.min=min
                    local tf= ostime(tab)
                    return 2,tf-tt
                else
                    --返回下一个时间的时间戳
                    return 2,time_tab[f_num+2]-tt

                end
            else
                 --返回下一个时间的时间戳
                 return 2,time_tab[f_num+1]-tt
            end
        
        else
            local hour=hr_tab[1]
            local min=min_tab[1]
            local tab=get_time_tab("d+1")
            tab.hour=hour
            tab.min=min
            local tf= ostime(tab)
            return 2,tf-tt
        end
    --min hour day * * 
    --10,20 4,5 3,4,5 (最大)
    elseif tab["min"]~="*" and tab["hour"]~="*" and tab["day"]~="*" and tab["month"]=="*" and tab["week"]=="*" then
        local hr_str=tab["hour"]
        local day_str=tab["day"]
        local min_str=tab["min"]
        local hr_tab=split_str(hr_str)
        local day_tab=split_str(day_str)
        local min_tab=split_str(min_str)
        table.sort(hr_tab)
        table.sort(day_tab)
        table.sort(min_tab)

        if hr_tab==nil or day_tab==nil or min_tab==nil then
            return nil
        end

        --获取转换后的时间戳
        local time_tab=min_hour_day(min_tab,hr_tab,day_tab)

        local tt
        if now~=nil then
            tt=now
        else
            tt=ostime()
        end

        table.insert(time_tab,tt)
        table.sort(time_tab)
        
        ngx_log(ngx.ERR,"time_tab is :",cjson.encode(time_tab))
        local f_num
        for k,v in pairs(time_tab) do
            if tt==v then
                f_num=k
                break
            end 
        end

        if f_num~=#time_tab then

            if time_tab[f_num]==time_tab[f_num+1] then
                if time_tab[f_num]==time_tab[#time_tab] then
                    --设置为下个月设置的第一个日期
                    local hour=hr_tab[1]
                    local day=day_tab[1]
                    local min=min_tab[1]
                    local now_day=tonumber(osdate("%d"))
                    local day_mount = month_days(tt)
                    -- "30 3,4,5 3,4,5 * *"
                    local cut_d=day_mount-now_day+day
                    local tab=get_time_tab("d+"..cut_d)
                    tab.hour=hour
                    tab.min=min
                    local tf= ostime(tab)
                    return 3,tf-tt
                else
                    --返回下一个时间的时间戳
                    return 3,time_tab[f_num+2]-tt

                end
            else
                 --返回下一个时间的时间戳
                 return 3,time_tab[f_num+1]-tt
            end
        
        else
            --设置为下个月设置的第一个日期
            local hour=hr_tab[1]
            local day=day_tab[1]
            local min=min_tab[1]
            local now_day=tonumber(osdate("%d"))
            local day_mount = month_days(tt)
            -- "30 3,4,5 3,4,5 * *"
            local cut_d=day_mount-now_day+day
            local tab=get_time_tab("d+"..cut_d)
            tab.hour=hour
            tab.min=min
            local tf= ostime(tab)
            return 3,tf-tt
        end

    -- min hour day month * 指的是那几个月的几号操作
    -- 10,20 4,5 1,2,3 5,8 * (最大限度)
    elseif tab["min"]~="*" and tab["hour"]~="*" and tab["day"]~="*" and tab["month"]~="*" and tab["week"]=="*" then  
        local min_str=tab["min"]
        local hr_str=tab["hour"]
        local day_str=tab["day"]
        local mon_str=tab["month"]

        local min_tab=split_str(min_str)
        local hr_tab=split_str(hr_str)
        local day_tab=split_str(day_str)
        local mon_tab=split_str(mon_str)

        table.sort(min_tab)
        table.sort(hr_tab)
        table.sort(day_tab)
        table.sort(mon_tab)

        if mon_tab==nil or day_tab==nil or hr_tab==nil or min_tab==nil then
            return nil
        end

        --获取转换过后的时间戳
        local time_tab=min_hour_day_mon(min_tab,hr_tab,day_tab,mon_tab)

        --对于转换后的时间戳进行排序，并且定位下一个需要执行的时间戳
        local tt
        if now~=nil then
            tt=now
        else
            tt=ostime()
        end

        table.insert(time_tab,tt)
        table.sort(time_tab)
        ngx_log(ngx.ERR,"time_tab is:",cjson.encode(time_tab))
        local f_num
        for k,v in pairs(time_tab) do
            if tt==v then
                f_num=k
                break
            end 
        end

        ngx_log(ngx.ERR,"f_num:",f_num)
        if f_num~=#time_tab then

            if time_tab[f_num]==time_tab[f_num+1] then
                if time_tab[f_num]==time_tab[#time_tab] then
                    --设置为下个月设置的第一个日期
                    local hour=hr_tab[1]
                    local day=day_tab[1]
                    local min=min_tab[1]
                    local month=mon_tab[1]
                    local year=osdate("%Y",tt)
                    year=year+1

                    local c={}
                    c.year=year
                    c.month=month
                    c.day=day
                    c.hour=hour
                    c.min=min

                    local tf=ostime(c)
                    -- ngx_log(ngx.ERR, "tt:-- ",4,tf-tt,tf)
                    return 4,tf-tt
            
                else
                    --返回下一个时间的时间戳
                    return 4,time_tab[f_num+2]-tt

                end
            else
                 --返回下一个时间的时间戳
                 return 4,time_tab[f_num+1]-tt
            end
        
        else 
            --设置为下个月设置的第一个日期
            local hour=hr_tab[1]
            local day=day_tab[1]
            local min=min_tab[1]
            local month=mon_tab[1]
            local year=osdate("%Y",tt)
            year=year+1

            local c={}
            c.year=year
            c.month=month
            c.day=day
            c.hour=hour
            c.min=min

            local tf=ostime(c)
            return 4,tf-tt

        end

    -- min hour * * week
    -- 10,20 4,5 * * 1,6 最大限度
    elseif tab["min"]~="*" and tab["hour"]~="*" and tab["day"]=="*" and tab["month"]=="*" and tab["week"]~="*" then
        local wk_str=tab["week"]
        local hr_str=tab["hour"]
        local min_str=tab["min"]
        -- ngx_log(ngx.ERR,"hr_str:",hr_str,"wk_str:",wk_str)
        local hr_tab=split_str(hr_str)
        local wk_tab=split_str(wk_str)
        local min_tab=split_str(min_str)
        ngx_log(ngx.ERR,"hr_tab:",cjson.encode(hr_tab),"wk_tab:",cjson.encode(wk_tab))
        table.sort(hr_tab)
        table.sort(wk_tab)
        table.sort(min_tab)
        if wk_tab==nil or hr_tab==nil or min_tab==nil then
            return nil
        end

        --获取转换过后的时间戳
        local time_tab=min_hour_week(min_tab,hr_tab,wk_tab)
        
        --对于转换后的时间戳进行排序，并且定位下一个需要执行的时间戳
        local tt
        if now~=nil then
            tt=now
        else
            tt=ostime()
        end

        table.insert(time_tab,tt)
        table.sort(time_tab)
        ngx_log(ngx.ERR,"time_tab is:",cjson.encode(time_tab))
        local f_num
        for k,v in pairs(time_tab) do
            if tt==v then
                f_num=k
                break
            end 
        end
        
        ngx_log(ngx.ERR,"f_num:",f_num)
        if f_num~=#time_tab then

            if time_tab[f_num]==time_tab[f_num+1] then
                if time_tab[f_num]==time_tab[#time_tab] then
                    --返回下周的设置的第一个时间的时间戳
                    local hr=hr_tab[1]
                    local wk=wk_tab[1]
                    local min=min_tab[1]
                    if wk==0 then
                        wk_tab[1]=7
                        table.sort(wk_tab)
                    end
                    
                    wk=wk_tab[1]
                    local now_wk=tonumber(osdate("%w"))
                    now_wk=lua_wk_linux(now_wk)
                    local cut_d=7-now_wk+wk
                    local tab=get_time_tab("d+"..cut_d)
                    tab.hour=hr
                    tab.min=min
                    local tf= ostime(tab)
                    
                    return 5,tf-tt
                else
                    --返回下一个时间的时间戳
                    return 5,time_tab[f_num+2]-tt

                end
            else
                 --返回下一个时间的时间戳
                 return 5,time_tab[f_num+1]-tt
            end
        
        else 
            --返回下周的设置的第一个时间的时间戳
            local hr=hr_tab[1]
            local wk=wk_tab[1]
            local min=min_tab[1]
            if wk==0 then
                wk_tab[1]=7
                table.sort(wk_tab)
            end
            
            wk=wk_tab[1]
            local now_wk=tonumber(osdate("%w"))
            now_wk=lua_wk_linux(now_wk)
            local cut_d=7-now_wk+wk
            local tab=get_time_tab("d+"..cut_d)
            tab.hour=hr
            tab.min=min
            local tf= ostime(tab)
            
            return 5,tf-tt
        end

    -- 其它，不进行解析    
    else
        return nil
    end

end

--将传入的字符串转成相对应的table
function _M:parse_cron(parse_str,now)
    local tab={}
    ngx_log(ngx.ERR,"parse_str for util is:",parse_str)
    for v in string.gmatch(parse_str,'[%w._/,%-*]+') do
        --如果可以转成整型直接转了，等下直接对比
        local i = tonumber(v)
        table.insert(tab, i and i or v)
    end
    
    if table.getn(tab) ~= 5 then
        return nil
    end

    local time_tab= {min = tab[1], hour = tab[2], day = tab[3], month = tab[4], week = tab[5]}
    local flag,timestamp=parse_cron_tab(time_tab,now)

    if flag then
        return flag,timestamp
    else
        return nil
    end

end

return _M

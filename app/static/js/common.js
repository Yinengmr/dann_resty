/**
 *Create by danny on 2018/11/29
 *@function 公用的js方法
*/
"use strict";

function common(){
    /**
     * @function 日期时间格式化
     * @var 参数fmt "yyyy/MM/dd hh:mm:ss" 2019/05/09 16:07:45
     * @var 默认参数fmt 'hh:mm:ss' 24小时时间
     * @var 参数fmt'q' 得到 1 2 3 4 
     * @var time 默认当前时间 可传入时间戳
     */
    function format_time(fmt='hh:mm:ss',time){
        var currentTime = time?parseInt(time)*1000:new Date().getTime();
        currentTime = new Date(currentTime)
        // var currentTime = new Date(1526632231)
        // console.log(currentTime) // Wed Jun 20 2018 16:12:12 GMT+0800 (中国标准时间)
        var o = {
        'M+': currentTime.getMonth() + 1, // 月份
        'd+': currentTime.getDate(), // 日
        'h+': currentTime.getHours(), // 小时
        'm+': currentTime.getMinutes(), // 分
        's+': currentTime.getSeconds(), // 秒
        'q+': Math.floor((currentTime.getMonth() + 3) / 3), // 季度
        'S': currentTime.getMilliseconds() // 毫秒
        }
        if (/(y+)/.test(fmt)) fmt = fmt.replace(RegExp.$1, (currentTime.getFullYear() + '').substr(4 - RegExp.$1.length))
        for (var k in o) {
        if (new RegExp('(' + k + ')').test(fmt)) fmt = fmt.replace(RegExp.$1, (RegExp.$1.length === 1) ? (o[k]) : (('00' + o[k]).substr(('' + o[k]).length)))
        }
        return fmt
    }
    /**@function 计算星期几*/
    function week() {
        var time = Math.round(new Date().getTime());
        var week = new Date().getDay();  
        var week_arr = [
        "星期日","星期一","星期二","星期三","星期四","星期五","星期六",
        ]
        return week_arr[week];
    }
    /**
     * @function 计算时间间隔
     * @var time1和time为时间戳或者格式化的时间 如 "2019-05-06 10:20:00"
     */
    function time_difference(time1,time2){
        if(!time2){
            return {
                d:0,
                h:0,
                m:0,
                s:0
            }
        }
        var current = time1?new Date(time1):new Date();
        let leftTime = parseInt((current - new Date(time2).getTime()));
        var d, h, m, s, ms;
        // console.log(leftTime);
        if (leftTime >= 0) {
            d = Math.floor(leftTime / 1000 / 60 / 60 / 24);
            h = Math.floor(leftTime / 1000 / 60 / 60 % 24);
            m = Math.floor(leftTime / 1000 / 60 % 60);
            s = Math.floor(leftTime / 1000 % 60);
            ms = Math.floor(leftTime % 1000);
            ms = ms < 100 ? "0" + ms : ms
            s = s < 10 ? "0" + s : s
            m = m < 10 ? "0" + m : m
            h = h < 10 ? "0" + h : h
        }else{
            // console.log(time1,time2)
            return {
                d:'0',
                h:'00',
                m:'00',
                s:'00'
            }
        }
        console.log(d,h,m,s)
        // console.log(d,h,m,s)
        return {
            // time_stamp:r,
            // t:t,
            d:d,
            h:h,
            m:m,
            s:s
        }
    }
    // 数组对象排序
    function compare(prop) {
        return function (obj1, obj2) {
            var val1 = obj1[prop];
            var val2 = obj2[prop];
            if (!isNaN(Number(val1)) && !isNaN(Number(val2))) {
                val1 = Number(val1);
                val2 = Number(val2);
            }
            if (val1 < val2) {
                return -1;
            } else if (val1 > val2) {
                return 1;
            } else {
                return 0;
            }            
        } 
    }
    return {
        format_time:format_time,
        week:week,
        time_difference:time_difference,
        compare:compare,
    }
}

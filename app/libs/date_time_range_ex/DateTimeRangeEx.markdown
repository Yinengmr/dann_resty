{
	
	dims:[{code:'H',name:'时'}，
		  {code:'D',name:'天'}，
	      {code:'W',name:'周'}，
	      {code:'M',name:'月'}，
	      {code:'Q',name:'季'}，
	      {code:'Y',name:'年'}
	     ]
}
define: [{'D',[{name:'今天',code:'d'  },
			   {name:'昨天',code:'d-1'},
			   {name:'前天',code:'d-2'}
			   {name:'前天至今天',code:'d-2，d'}
			 ]},
		 {'W',[{name:'本周',code:'w'  },
			   {name:'上周',code:'w-1'},
			   {name:'前周',code:'w-2'}
			 ]},
		 {'M',[{name:'本月',code:'m'  },
			   {name:'上月',code:'m-1'},
			   {name:'前月',code:'m-2'}
			 ]},
		 {'Q',[{name:'本季',code:'q'  },
			   {name:'上季',code:'q-1'},
			   {name:'前季',code:'q-2'}
			 ]},
		 {'Y',[{name:'今年',code:'y'  },
			   {name:'去年',code:'y-1'},
			   {name:'前年',code:'y-2'}
			 ]},
			 
		]
// 环比近三年第一季趋势图
	前年第一季 Y-2:Q1
	去年第一季 Y-1:Q1
	今年第一季 Y:Q1
// 环比近三年当季趋势图
	前年第一季 Y-2:Q
	去年第一季 Y-1:Q
	今年第一季 Y:Q
// 环比近三季趋势图
	当前季 Q
	上一季 Q-1
	前一季 Q-2
DateTimeRangeEx 
日期时间区间表达式 
格式定义:
Symbol 	Meaning					Range
S		秒	second-of-minute	0-59
N		分	minute-of-hour		0-59
H		时	hour-of-day			0-23
D		天	day-of-year			1-365
W		周	week-of-year		1-54
M		月	month-of-year		1-12
Q		季	quarter-of-year		1-4
Y		年	year-of-era			0001-9999
G		世纪 era					0-99
运算符号定义:
1.  : 范围约束定义符, 在其左侧是范围表达式, 在其右侧是区间偏移量表达式(可以省略)
2.  , 区间定义符, 在其左侧是开始时间表达式, 在其右侧是结束时间表达式(当区间值为1时,可以省略)
       例:    D, D+1  = D    // 今天, 时间范围 当天的00:00 ~ 24:00
	      	  W, W+1 = W  // 本周, 时间范围 本周的第一天00:00 ~ 最后一天的 24:00
              M, M+1 = M   //  本月, 时间范围 当月的第一天的00:00 ~ 最后一天的 24:00
3. + - 正负偏移量
表达式定义0:
[Expression1] : [Expression2] ,  [Expression3] : [Expression4] 
[开始时间表达式] 		     ,  [ 结束时间表达式]
例如:
 M-2,M   表示  今年上两个月之间的时间
 	 
表达式定义1:
[Constant] [+ / -] [ Offset ]			
[常量] [运算符] [偏移量]
例: 
 Y    表示本年
 Y-1 表示去年
 Y-2 表示前年
 Y-n 表示n年前
定义2:
[ Symbol ] [ Range ]
[时间标识] [ 区间值]
例: 
H21第21小时
D2  第2天
W3 第3周
M1 第一个月
Q4  第4季
 
 
表达式分解逻辑:
先用”,”符号 分裂用开始与结束两个表达式
再将其每一部分的表达式,按”:” 再分裂成 范围约束表达式 和 偏移量表达式
3.   找最小单位的时间标识, 
       例如 M-2,M 最小时间标识是月,其默认精度就是天
	       W-1 	  最小时间标识是周,其默认精度就是天
	       D-1	  最小时间标识是天,其默认精度就是时
{
 id: 1
 name: '本月人數總數'
 groups:[
 		 {     id: 1，
 		     name: '分組一'，
 		  is_show: true,
 		  	items: [
 		  			 {
 		  			          id: 1,
 		  			         src: 'man_qty',
 		  			  time_range: 'curr_week'
 		  			  chart_type: 'bar',
 		  			  	   color: '#ffffff'
 		  			  },
 		  			  {
 		  			          id: 2,
 		  			         src: 'man_qty',
 		  			  time_range: 'proi_week'
 		  			  chart_type: 'bar',
 		  			  	   color: '#fff000'
 		  			  }
 		  		   ]
 		 },
 		 {     id: 2，
 		     name: '分組二'，
 		  is_show: true,
 		  	items: [
 		  			 {
 		  			          id: 1,
 		  			         src: 'man_qty',
 		  			  time_range: 'curr_week'
 		  			  chart_type: 'bar',
 		  			  	   color: '#ffffff'
 		  			  },
 		  			  {
 		  			          id: 2,
 		  			         src: 'man_qty',
 		  			  time_range: 'proi_week'
 		  			  chart_type: 'bar',
 		  			  	   color: '#fff000'
 		  			  }
 		  		   ]
 		 }
 	   ]	
}
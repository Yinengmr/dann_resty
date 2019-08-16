/*******************************************/
/**      author:  hoho                   **/
/**      http://www.thinkcart.net        **/
/******************************************/

//产生随机数
function rand(Min,Max){
    var Range = Max - Min;
    var Rand = Math.random();
    return(Min + Math.round(Rand * Range));
}
//定义参数
var index = 1,              //当前选中对象的位置
    fast,                   //在哪个位置开始加速
    num   = 14,              //共有多少个抽奖对象
    cycle,                  //转动多少圈
    speed = 300,            //开始时速度
    flag  = false,          //正在抽奖标志
    lucky,                  //中奖号码，实际应用由后台产生
    award,                  //奖品名称
    lottery;                //抽奖对象

//开始抽奖
function start_lottery(){
    if(flag){
        //alert('正在抽奖，请等待抽奖结果！');
        //return false;
        return void(0);
    }
    flag=true;
    index = 1;              //当前选中对象的位置
    fast  = rand(3,6);      //在哪个位置开始加速
    cycle = rand(3,5);      //转动多少圈
    speed = 300;            //开始时速度

	lucky = 3;    //中奖号码
    award = 1111;  //奖品名称
	show_lottery();
}
//抽奖效果展示
function show_lottery(){
    if(index>num){
        index = 1;
        cycle--;
    }
    $('#lottery li').css('opacity',0.3);
    $('#lottery_'+index).css('opacity',1);
    if(index>fast) speed=100;//开始加速
    if(cycle==0 && lucky-index<rand(2,5)) speed=speed+200;//开始减速
    if(cycle<=0 && index==lucky){//结束抽奖，选中号码
        clearTimeout(lottery);
        setTimeout(function(){
            $('#lottery li').css('opacity',1);
            alert('恭喜您获得：'+award);
        },1200);
        flag = false;
    }else{
        lottery = setTimeout(show_lottery,speed);
    }
    index++;
}
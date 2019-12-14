var APP = APP || {}
var common_js = new common();
var audio04= new Audio("../../static/music/04.mp3");
var audio05= new Audio("../../static/music/05.mp3");
var audio= new Audio("../../static/music/03.mp3");//这里的路径写上mp3文件在项目中的绝对路径
window.onload = function(){
    // 模塊初始化；
    APP.line_emp.init();
}
;(function(KK) {
    var _this = null;
    KK.line_emp = KK.line_emp || {};
    _this = KK.line_emp = {
        Main: {
            data:function(){
                return {
                    //定义参数
                    index: 1,                       //当前选中对象的位置
                    fast:'',                        //在哪个位置开始加速
                    num: 15,                        //共有多少个抽奖对象
                    cycle:'',                       //转动多少圈
                    speed: 300,                     //开始时速度
                    flag : false,                   //正在抽奖标志
                    lucky:'',                       //中签号码
                    emp_name:'',                    //中签人名
                    message:'',                     // 公告、信息
                    emp_no:'',                      //中签工号
                    lottery:'',                     //抽签
                    emp_all:[],                      // 所有人员
                    class_true:false,

                    drawer: false,
                    direction: 'rtl',

                    // 第一屏抽签历史
                    chouqian_his:[],

                    // 抽签类型
                    radio_model:2 ,

                    // 是否刷新中
                    geting:false,

                    // 是否显示礼品抽奖
                    is_lipin:true,
                    // 历史记录类型
                    his_raido:2,
                    his_chouqian:[],
                }
            },
            methods:{
                top4(i){
                    if(i<5){
                        return "color:#51dacf"
                    }
                },
                // 关闭历史抽屉
                handleClose(done) {
                    audio05.play();
                    done();
                    // this.$confirm('确认关闭？')
                    // .then(_ => {
                    //     done();
                    // })
                    // .catch(_ => {});
                },
                // his
                get_his(){
                    audio05.play();
                    let root = this;
                    if(root.flag){
                        alert('正在抽奖，请等待抽奖结果！');
                        //return false;
                        return false;
                    }
                    
                    root.drawer = true
                    root.get_his_data(2);
                    var drawer = document.querySelector("#drawer").querySelector("div").querySelector("div");
                    // console.log(drawer);
                    drawer.style.width = "44%";
                },
                // 历史抽签全部
                his_raido_change2(e){
                    audio05.play();
                    console.log(e);
                    this.get_his_data(2);
                },
                his_raido_change1(e){
                    audio05.play();
                    console.log(e);
                    // $('#lottery li div').attr("class", "li_div_bg");
                    this.message = '';
                    this.get_his_data(1);
                },
                get_his_data(type){
                    let root = this;
                    if(type==1){
                        if(root.radio_model==0){
                            return false;
                        }
                        if(root.radio_model==2){
                            let url = "/action/emp_?lipin=1"
                            root.get_ajax(url,function(res){
                                console.log(res)
                                root.emp_all = res.data.data
                                if(root.chouqian_his.length>=root.emp_all.length){
                                    clearTimeout(root.lottery);
                                    
                                    root.class_true=true;
                                    // root.get_his_data(1);
                                    setTimeout(function(){
                                        $('#lottery li').css('opacity',1);
                                        root.class_true=false;
                                        root.message = '所有人都已中奖！祝贺活动圆满成功！'
                                    },2200);
                                    root.flag = false;
                                }
                            })
                            
                        }
                        let url = '/action/his?type='+root.radio_model;
                        root.get_ajax(url,function(res){
                            console.log(res)
                            root.chouqian_his = res.data.data
                        })
                        
                        
                    }else{
                        let url = '/action/his?type='+root.his_raido;
                        if(root.his_raido==0){
                            url = '/action/his?type=';
                        }
                        root.get_ajax(url,function(res){
                            console.log(res);
                            root.his_chouqian = res.data.data
                        })
                    }
                },
                //产生随机数
                rand(Min,Max){
                    var Range = Max - Min;
                    var Rand = Math.random();
                    return(Min + Math.round(Rand * Range));
                },
                //开始抽奖
                start_lottery(){
                    console.log('开始抽奖')
                    // return false;
                    let root = this;
                    if(root.flag){
                        alert('正在抽奖，请等待抽奖结果！');
                        //return false;
                        return false;
                    }
                    if(root.radio_model == 2 && root.chouqian_his.length>=root.emp_all.length){
                        alert('所有人都已中奖！祝贺活动圆满成功！');
                        return false;
                    }
                    root.flag=true;
                    root.index = root.rand(0,20);              //当前选中对象的位置
                    root.fast  = root.rand(2,20);      //在哪个位置开始加速
                    root.cycle = root.rand(1,2);      //转动多少圈
                    root.speed = 300;            //开始时速度

                    // 口令输入
                    if(root.radio_model==1){

                    }
                    // 后端抽签
                    root.post_ajax('/action?type='+root.radio_model,{},function(res){
                        if(res.rv!=200){
                            root.$Message.info(res.msg);
                            root.flag=false;
                            return false;
                        }
                        console.log(res)
                        root.lucky = res.lucky.no
                        root.emp_name = res.lucky.name
                        root.emp_no = res.lucky.emp_no
                        root.class_true=false;
                        root.show_lottery();
                        
                    })

                },
                //抽奖效果展示
                show_lottery(){
                    let root = this
                    audio.load();
                    if(root.index>root.num-2){
                        root.index = 0;
                        root.cycle--;
                    }
                    // $('#lottery li div').attr("class", "li_div_bg");
                    if(root.index > 0){
                        $('#lottery_'+(root.index-1)+' div').attr("class","li_div_bg");
                    }
                    if(root.index == 0){
                        $('#lottery_24 div').attr("class","li_div_bg");
                    }

                    $('#lottery_'+root.index+' div').attr("class","li_div_current_bg");

                    root.message = root.emp_all[root.index].name
                    var audio1= new Audio("../../static/music/01.mp3");
                    audio1.play();
                    console.log(root.index,root.message)
                    // $('#lottery_8').css('opacity',1);
                    if(root.index>root.fast){
                        root.speed=100;//开始加速
                    } 
                    if(root.cycle==0 && root.lucky-root.index<=5){
                        root.speed=root.speed+250;//开始减速
                    } 
                    // console.log(root.cycle)
                    if(root.cycle<=0 && root.index==root.lucky-1){//结束抽奖，选中号码
                        clearTimeout(root.lottery);
                        
                        spawnSeed();
                        // S.init('恭喜：'+root.emp_name+' 中签');
                        for(let i=0;i<6;i++){
                            setTimeout(function(){
                                setTimeout(function(){
                                    spawnSeed();
                                },70)
                                setTimeout(function(){
                                    spawnSeed();
                                },100)
                                setTimeout(function(){
                                    spawnSeed();
                                },200)
                                setTimeout(function(){
                                    spawnSeed();
                                },600)
                            },700*i)
                        }
                        let i = root.index;
                        root.class_true=true;

                        audio04.play();
                        setTimeout(function(){
                            audio.volume = 0.82;
                            audio.play();
                        },250)
                        $('#lottery_'+i+' div').attr("class","li_div_bg li_div_lucky");

                        // 戴绿帽
                        if(root.radio_model == 2){
                            root.emp_all[i].status = 1;
                        }
                        // 查询历史记录
                        root.get_his_data(1);

                        setTimeout(function(){
                            root.message = '恭喜：'+root.emp_name+' 中签';
                            root.class_true=false;
                        },1200);
                        root.flag = false;
                    }else{
                        root.flag = true;
                        root.lottery = setTimeout(
                            function(){
                                root.show_lottery()
                            },root.speed
                        );
                    }
                    root.index++
                },
                // 请求参与抽奖的人员
                get_emp_all(){
                    let root = this;
                    
                    if(root.flag){
                        alert('正在抽奖，请等待抽奖结果！');
                        return false;
                    }
                    root.geting = true;
                    root.message = ''
                    let url = '/action/emp'
                    root.get_ajax(url,function(res){
                        console.log(res.data)
                        root.emp_all = res.data.data
                        root.num = root.emp_all.length+1
                        setTimeout(function(){
                            root.geting = false;
                        },200)
                        
                    })
                    $('#lottery li div').attr("class", "li_div_bg");
                },
                get_ajax(url,callback){
                    let root =this;
                    axios.get(url)
                    .then(function(res){
                        if(res.data.rv !=200){
                            root.Message.warning(res.data.msg)
                            // setTimeout(()=>{
                            //     common_js.redirect_login(res.data.rv);
                            // },2000)
                            return false;
                        }
                        callback(res)
                    })
                    .catch(function(err){
                        root.Message.error('系统错误！');
                        callback(err)
                        setTimeout(function(){
                            root.geting = false;
                        },200)
                    })
                },
                /*公用的ajax post*/
                post_ajax(url,data,callback){
                    let root =this;
                    axios.post(url,data)
                    .then(function(res){
                        // if(res.data.rv !=200){
                        //     root.$Message.warning(res.data.msg)
                        // }
                        callback(res.data)
                    })
                    .catch(function(err){
                         callback(err)
                    })
                },
                // 刪除 禮品交換記錄
                del_his(row){
                    let root = this;
                    let url = '/action/del_his';
                    let data = row
                    axios.post(url,data)
                    .then(function(res){
                        if(res.data.rv !=200){
                            root.$Message.info(res.data.msg);
                        }else{
                            root.$Message.info(res.data.msg)
                            root.message = ''
                        }
                        root.get_his_data(1);
                        root.get_his_data(2);
                    })
                    .catch(function(err){
                         
                    })
                }
            },
            created: function () {
                console.log('aa')
                this.get_emp_all();
                this.get_his_data(1);
                console.log(common_js.time_difference('2019-11-14 17:19:00','2019-11-14 17:17:00'));

/*                 var parent=document.getElementById("app");
                var child=document.createElement("span");//创建新的节点
                child.classList.add("play");
                child.setAttribute("id","play");
                parent.appendChild(child); //在第二个节点之前插入新创建的节点

                setTimeout(function(){
                    $('.play').fireworks({ 
                        sound: false, // sound effect
                        opacity: 0.9, 
                        width: '100px', 
                        height: '100px' 
                    });
                },2000)
                
                setTimeout(function(){
                    var parent=document.getElementById("app");
                    let child=document.getElementById("play");
                    parent.removeChild(child);
                },7000) */
            }
        },
        init: function() {
            var Component = Vue.extend(_this.Main);
            new Component().$mount('#app');
        },
    }
}(APP))
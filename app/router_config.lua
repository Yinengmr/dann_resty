--- 業務路由管理
return {
    index  = {
        { uri = "/",    router = "app.routes.index"},  -- 主入口
    },
    -- 抽签程序
    action = {
        { uri = "/action",    router = "app.routes.action"},  
    }
}
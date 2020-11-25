--- 業務路由管理
return {
    index  = {
        { uri = "/",    router = "app.routes.index"},  -- 主入口
    },
    -- 抽签程序
    action = {
        { uri = "/action",    router = "app.routes.action"},  
        { uri = "/nike",    router = "app.routes.nike"},  
    },
    login = {
        { uri = "/login", router = "app.routes.login"},
        -- { uri = "/logout", router = "app.routes.logout"},
    },
    users = {
        { uri = "/users", router = "app.routes.users"},
    }
}
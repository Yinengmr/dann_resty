### xlsx2lua 封裝說明

## book.lua 方法說明
1. new(file) 
   功能:新建一個book對象
   傳入參數說明:
        file xlsx文件
   返回參數說明:
        res  成功返回book對象,失敗為nil
        err  成功為nil,失敗返回錯誤信息
2. get_sheet_by_name(sheet_name)
   功能:根據工作薄名稱返回一個sheet對象
   傳入參數說明:
        sheet_name 工作薄名稱
   返回參數說明:
        res  成功返回sheet對象,失敗為nil
        err  成功為nil,失敗返回錯誤信息
3. get_sheet_by_index(sheet_index)
   功能:根據工作薄索引返回一個sheet對象(索引從1開始)
   傳入參數說明:
        sheet_index 工作薄索引
   返回參數說明:
        res  成功返回sheet對象,失敗為nil
        err  成功為nil,失敗返回錯誤信息
4. get_sheets()
   功能:根據所有工作薄
   返回參數說明:
        res  工作薄table name為工作薄名稱 ins為工作薄數據
5. save(file_dir)
   功能:保存該excel文件到指定目錄
   傳入參數說明:
        file_dir 保存文件目錄
   返回參數說明:
        res  成功返回true,失敗返回false
        err  成功為nil,失敗返回錯誤信息
6. save_insert(file_dir,file_path,author,description)
   功能:保存該excel文件到指定目錄并插入數據庫
   傳入參數說明:
        file_dir 保存文件目錄
        file_path 访问文件路径
        author 操作人工號
        description 文件說明
   返回參數說明:
        res  成功返回true,失敗返回false
        msg  成功為插入數據庫id,失敗返回錯誤信息


## sheet.lua 方法說明
1. get_header() 
   功能:獲取工作薄頭部
   返回參數說明:
        res  返回工作薄頭部(工作薄第一行)
2. get_data()
   功能:獲取工作薄數據
   返回參數說明:
        res  返回工作薄數據(工作薄第二行開始至結束)
3. set_header_map(header_map)
   功能:設置頭部映射關係
   傳入參數說明:
        header_map 映射table key為數據索引key val為頭部名稱
   返回參數說明:
        res  成功返回true,失敗返回false
        err  成功為nil,失敗返回錯誤信息
4. header_verify(fun_header_ver)
   功能:設置頭部檢查方法
   傳入參數說明:
        fun_header_ver 自定義檢查方法,該方法提供一個參數用來接收工作薄頭部數據
5. get_map_data(val,val_keys)
   功能:獲取val中指定key的值
   傳入參數說明:
        val 工作薄中某行數據
        val_keys 數據索引key組成的table
   返回參數說明:
        res  失敗返回false,成功返回數據集合
        err  成功為nil,失敗返回錯誤信息
6. chk_null(v,vals_keys,success_cb,false_cb)
   功能:空值檢查
   傳入參數說明:
        v 工作薄中某行數據
        val_keys 數據索引key組成的table
        success_cb 成功回調方法,提供一個參數用來接收成功數據
        false_cb 失敗回調方法,提供一個參數用來接收失敗數據
   返回參數說明:
        res  失敗返回false,成功返回true
        err  成功為nil,失敗返回錯誤信息
7. chk_format(v,vals_keys,format,success_cb,false_cb)
   功能:格式檢查
   傳入參數說明:
        v 工作薄中某行數據
        val_keys 數據索引key組成的table
        format 正則式
        success_cb 成功回調方法,提供一個參數用來接收成功數據
        false_cb 失敗回調方法,提供一個參數用來接收失敗數據
   返回參數說明:
        res  失敗返回false,成功返回true
        err  成功為nil,失敗返回錯誤信息
8. chk_str_in_table(v,vals_keys,chk_table,success_cb,false_cb)
   功能:存在檢查
   傳入參數說明:
        v 工作薄中某行數據
        val_keys 數據索引key組成的table
        chk_table 範圍table
        success_cb 成功回調方法,提供一個參數用來接收成功數據
        false_cb 失敗回調方法,提供一個參數用來接收失敗數據
   返回參數說明:
        res  失敗返回false,成功返回true
        err  成功為nil,失敗返回錯誤信息
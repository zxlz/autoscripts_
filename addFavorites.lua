--"shownewsindex"  KEYS[1]
--fav_[userkey]    KEYS[2]
--fav_[newskey]    KEYS[3]


local showjson=redis.call("hget",KEYS[1],ARGV[1]);
if showjson then
    --尝试移除
    local i=redis.call("ZREM",KEYS[2],showjson)
    --成功移除，执行取消收藏，否则执行收藏
    if i>0 then
        redis.call("HINCRBY","viewscount",KEYS[3],-1)
        return 0
    else
        redis.call("HINCRBY","viewscount",KEYS[3],1)
        --取最后一个元素的排名+1，默认0
        local any=redis.call("ZRANGE",KEYS[2],-1,-1,"WITHSCORES")
        if #any>0 then
            redis.call("SET","test",any[#any])
            redis.call("zadd",KEYS[2],any[#any]+1,showjson)
        else
            redis.call("zadd",KEYS[2],0,showjson)
        end
        return 1
    end
else
    return -1
end
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require 'mp.options'

local o = {
    -- 是否自动加载本地弹幕
    autoload = true,
    -- 指定 DanmakuFactory 程序的路径，支持绝对路径和相对路径
    -- 默认值会在环境变量 PATH 中或 mpv 程序旁查找该程序
    DanmakuFactory_Path = 'DanmakuFactory',
    --分辨率
    resolution = "1920 1080",
    --速度
    scrolltime = "12",
    --字体
    fontname = "Microsoft YaHei",
    --大小 
    fontsize = "40",
    --透明度(1-255)  255 为不透明
    opacity = "150",
    --阴影
    shadow = "0",
    --粗体 true false
    bold = "true",
    --弹幕密度 整数(>=-1) -1：表示不重叠 0：表示无限制 其他表示限定条数
    density = "0.0",
    --全部弹幕的显示范围(0.0-1.0)
    displayarea = "0.8",
    --描边 0-4
    outline = "1",
}

options.read_options(o, _, function() end)

local danmaku_file = nil
local sec_sub_visibility = mp.get_property_native("secondary-sub-visibility")
local sec_sub_ass_override = mp.get_property_native("secondary-sub-ass-override")

local function get_sub_count()
    local count  = 0
    local tracks = mp.get_property_native("track-list")
    for _, track in ipairs(tracks) do
        if track["type"] == "sub" then
            count = count + 1
        end
    end
    return count
end

local function file_exists(path)
    if path then
        local meta = utils.file_info(path)
        if meta and meta.is_file then
            return true
        else
            return false
        end
    else
        return false
    end
end

-- load danmaku
local function load_danmaku(danmaku_file)
    if not file_exists(danmaku_file) then return end
    msg.info("成功挂载本地弹幕文件")
    -- 如果可用将弹幕挂载为次字幕
    if sec_sub_ass_override then
        mp.commandv("sub-add", danmaku_file, "auto")
        local sub_count = get_sub_count()
        mp.set_property_native("secondary-sub-ass-override", "yes")
        mp.set_property_native("secondary-sid", sub_count)
        mp.set_property_native("secondary-sub-visibility", true)
    else
        -- 挂载subtitles滤镜，注意加上@标签，这样即使多次调用也不会重复挂载，以最后一次为准
        mp.commandv('vf', 'append', '@danmaku:subtitles=filename="'..danmaku_file..'"')
        -- 只能在软解或auto-copy硬解下生效，统一改为auto-copy硬解
        mp.set_property('hwdec', 'auto-copy')
    end
end

-- danmaku xml2ass
local function danmaku2ass(force)
    if not force and not o.autoload then return end
    local path = mp.get_property("path")
    if not path or path:find('^%a[%w.+-]-://') then return end
    local dir = utils.split_path(path)
    local fliename = mp.get_property('filename/no-ext')
    local danmaku_xml = utils.join_path(dir, fliename .. ".xml")
    if not file_exists(danmaku_xml) then return end

    local directory = utils.split_path(os.tmpname())
    danmaku_file = utils.join_path(directory, "danmaku.ass")

    local arg = { mp.command_native({ "expand-path", o.DanmakuFactory_Path }),
       "-o", danmaku_file,
       "-i", danmaku_xml,
       "--resolution", o.resolution,
       "--scrolltime", o.scrolltime,
       "--fontname", o.fontname,
       "--fontsize", o.fontsize,
       "--opacity", o.opacity,
       "--shadow", o.shadow,
       "--bold", o.bold,
       "--density", o.density,
       "--displayarea", o.displayarea,
       "--outline", o.outline,
    }

    -- convert to ass
    mp.command_native_async({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        args = arg,
    },function(res, val, err)
        if err == nil
        then
            load_danmaku(danmaku_file)
        else
            msg.debug(err)
        end
    end)
end

-- toggle function
function asstoggle()
    if not file_exists(danmaku_file) then return end
    local sec_visibility = mp.get_property_bool("secondary-sub-visibility")
    if sec_sub_ass_override and sec_visibility then
        msg.debug("隐藏本地弹幕")
        mp.set_property_native("secondary-sub-visibility", false)
        return
    elseif sec_sub_ass_override == nil then
        -- if exists @danmaku filter， remove it
        for _, f in ipairs(mp.get_property_native('vf')) do
            if f.label == 'danmaku' then
                msg.debug("卸载本地弹幕")
                mp.commandv('vf', 'remove', '@danmaku')
                return
            end
        end
    end
    -- otherwise, load danmaku
    if file_exists(danmaku_file) then load_danmaku(danmaku_file) end
end

mp.add_key_binding(nil, 'toggle-local-danmaku', asstoggle)
mp.add_key_binding(nil, 'loade-local-danmaku', danmaku2ass(true))
mp.register_event("file-loaded", danmaku2ass)
mp.register_event("end-file", function()
    asstoggle()
    if file_exists(danmaku_file) then
        os.remove(danmaku_file)
    end
    if sec_sub_ass_override then
        mp.set_property_native("secondary-sub-visibility", sec_sub_visibility)
        mp.set_property_native("secondary-sub-ass-override", sec_sub_ass_override)
    end
end)

--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    I took the idea for the HLS gradients from AdiButtonAuras. I still don't
    know if this is worth all this processing, OR if this is fast enough to
    run every frame.

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA = LBA or {}

local min, max = math.min, math.max

local function hueToV(m1, m2, hue)
    hue = hue % 1
    if hue < 1/6 then
        return m1 + (m2-m1)*hue*6
    elseif hue < 1/2 then
        return m2
    elseif hue < 2/3 then
        return m1 + (m2-m1)*(2/3-hue)*6
    else
        return m1
    end
end

local function hlsToRgb(h, l, s)
    if s == 0 then
        return l, l, l
    end
    local m2
    if l < 0.5 then
        m2 = l * (1+s)
    else
        m2 = (l+s) - (l*s)
    end
    local m1 = 2*l - m2
    return hueToV(m1, m2, h+1/3), hueToV(m1, m2, h), hueToV(m1, m2, h-1/3)
end

local function rgbToHls(r, g, b)
    local minC, maxC = min(r, g, b), max(r, g, b)
    local l = (minC + maxC)/2
    if minC == maxC then
        return 0, l, 0
    end
    local h, s
    if l < 0.5 then
        s = (maxC-minC) / (maxC+minC)
    else
        s = (maxC-minC) / (2-maxC-minC)
    end
    local rc = (maxC-r) / (maxC-minC)
    local gc = (maxC-g) / (maxC-minC)
    local bc = (maxC-b) / (maxC-minC)
    if r == maxC then
        h = bc - gc
    elseif g == maxC then
        h = 2 + rc - bc
    else
        h = 4 + gc - rc
    end
    return (h/6) % 1, l, s
end

local function interpolateHls(perc, h1, l1, s1, h2, l2, s2)
    -- L and S are linear interpolated
    local l = l1 + (l2-l1) * perc
    local s = s1 + (s2-s1) * perc

    -- Hue is a degree coordinate in radians on a circle that wraps. We want
    -- the smallest of the two angles between them.
    local dh = h2 - h1
    if dh < -0.5  then
        dh = dh + 1
    elseif dh > 0.5 then
        dh = dh - 1
    end

    h = (h1 + dh*perc) % 1
    return h, l, s
end

-- Colors in HLS so we don't have to do the math to unnecessarily convert
-- them every frame.

local Red = { rgbToHls(1, 0, 0) }
local Yellow = { rgbToHls(1, 1, 0) }
local White = { rgbToHls(1, 1, 1) }

-- In theory this could be memoized for the values < 10s because they are
-- truncated to 0.1 of a second before this is called. But I don't know
-- enough about math.ceil to know if that's safe, and I'm guaranteed to
-- forget that at some point and blow out memory infinitely.

function LBA.TimerRGB(duration)
    if duration <= 3 then
        return rgbToHls(
            interpolateHls(
                duration/3
                Red[1], Red[2], Red[3],
                Yellow[1], Yellow[2], Yellow[3]
            )
        )
    elseif duration <= 10 then
        return rgbToHls(
            interpolateHls(
                (duration-3)/7,
                Yellow[1], Yellow[2], Yellow[3],
                White[1], White[2], White[3]
            )
        )
    else
        return 1, 1, 1
    end
end

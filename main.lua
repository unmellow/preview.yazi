local M = {}

function M:peek(job)
	-- 1. Ignore directories
	if job.file.cha.is_dir then
		return
	end

	-- 2. Obtain cache URL from Yazi
	local cache = ya.file_cache(job)
	if not cache then
		return ya.preview_widgets(job, {
			ui.Paragraph(job.area, {
				ui.Line("Unable to allocate file cache for preview."),
			}),
		})
	end

	-- 3. If thumbnail already exists in cache, render it
	local cha = fs.cha(cache)
	if cha and cha.len > 0 then
		return ya.image_show(cache, job.area)
	end

	-- 4. Try generating video thumbnail via ffmpegthumbnailer
	local child, err = Command("ffmpegthumbnailer")
		:args({
			"-i",
			tostring(job.file.url),
			"-o",
			tostring(cache),
			"-s",
			"800",
			"-q",
			"6",
		})
		:spawn()

	if child then
		local status = child:wait()
		if status and status:success() then
			return ya.image_show(cache, job.area)
		end
	end

	-- 5. Fallback for non-video files or failed thumbnails
	local err_msg = err and tostring(err) or "No preview available for this file type."
	return ya.preview_widgets(job, {
		ui.Paragraph(job.area, {
			ui.Line(err_msg),
		}),
	})
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		local step = math.floor(job.units * job.area.h / 10)
		ya.manager_emit("peek", {
			math.max(0, job.skip + step),
			only_if = job.file.url,
		})
	end
end

return M

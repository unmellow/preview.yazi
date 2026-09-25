local M = {}

function M:peek(job)
	-- Get a designated cache path for this file from Yazi
	local cache = ya.file_cache(job)
	if not cache then
		return
	end

	-- Generate thumbnail if it does not already exist in cache
	local cha = fs.cha(cache)
	if not cha or cha.len == 0 then
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

		if not child then
			return ya.preview_widgets(job, {
				ui.Paragraph(job.area, {
					ui.Line(string.format("Failed to spawn ffmpegthumbnailer: %s", tostring(err))),
				}),
			})
		end

		local status = child:wait()
		if not status or not status:success() then
			return ya.preview_widgets(job, {
				ui.Paragraph(job.area, {
					ui.Line("ffmpegthumbnailer failed to generate video thumbnail."),
				}),
			})
		end
	end

	-- Render the cached image directly into Yazi's preview pane
	return ya.image_show(cache, job.area)
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

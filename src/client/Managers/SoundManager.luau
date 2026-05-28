local SoundManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundsFolder = ReplicatedStorage.Assets.Sounds

SoundManager.Settings = {
	Master = 1,
	Music = 0.5,
	SFX = 0.5,
	Ambience = 0.5
}

function SoundManager:PlaySound(data)
	local soundName = data.soundName
	local category = data.category
	local position = data.position
	local pitchOn = data.pitchOn or true
	
	local soundTemplate = SoundsFolder[category]:FindFirstChild(soundName)
	if not soundTemplate then 
		warn("Sound not found:", soundName)
		return 
	end

	local sound = soundTemplate:Clone()
	sound.Parent = workspace

	local categoryVolume = self.Settings[category] or 0.5
	local masterVolume = self.Settings.Master
	sound.Volume = soundTemplate.Volume * categoryVolume * masterVolume

	if position then
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = position
		attachment.Parent = workspace
		sound.Parent = attachment
	end

	if pitchOn then
		local rngFactor = math.random(-5, 5) / 100
		local pitch = Instance.new("PitchShiftSoundEffect")
		pitch.Parent = sound
		pitch.Octave = 1 + rngFactor
	end
	
	sound:Play()

	task.delay(sound.TimeLength + 0.1, function()
		if position then
			sound.Parent:Destroy()
		else
			sound:Destroy()
		end
	end)

	return sound
end

function SoundManager:SetVolume(category, volume)
	self.Settings[category] = math.clamp(volume, 0, 1)
end

return SoundManager
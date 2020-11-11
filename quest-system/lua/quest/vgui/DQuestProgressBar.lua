local PANEL = {}

function PANEL:Init()
	self.Max = 0
	self.Current = 0
	self.Finished = false

	self.ProgressBar = vgui.Create("DPanel", self)
	self.ProgressBar.Paint = function(this) // I hate use "this" as pointer on self
		surface.SetDrawColor(Color(35, 35, 35))
		surface.DrawRect(0, 0, this:GetWide(), this:GetTall())

		surface.SetDrawColor((self:GetCurrent() >= self:GetMax() || self.Finished) && Color(0, 170, 0) || Color(255, 200, 0))
		surface.DrawRect(0, 0, this:GetWide() * (math.Clamp(!self.Finished && self:GetCurrent() || self:GetMax(), 0, self:GetMax()) / self:GetMax()), this:GetTall())
	end

	self.ProgressLabel = vgui.Create("DLabel", self.ProgressBar)
	self.ProgressLabel:SetFont("PS2_MediumLarge")
	self.ProgressLabel:SetTextColor(COLOR_WHITE)
	self.ProgressLabel:Dock(FILL)
	self.ProgressLabel:SetContentAlignment(8)
	self.ProgressLabel:SetText("0/0")
	self.ProgressLabel.Paint = function(this)
		if ( self:GetCurrent() < self:GetMax() && !self.Finished ) then
			self:SetText(self:GetCurrent() .. "/" .. self:GetMax())
		else
			self:SetText("Abgeschlossen")
		end
	end
end

function PANEL:SetMax(val)
	self.Max = tonumber(val)
end

function PANEL:SetCurrent(val)
	self.Current = tonumber(val)
end

function PANEL:GetMax()
	return self.Max
end

function PANEL:GetCurrent()
	return self.Current
end

function PANEL:SetText(text)
	self.ProgressLabel:SetText(text)
end

function PANEL:ApplySchemeSettings( )

end

function PANEL:PerformLayout( )

end

function PANEL:Paint()

end

derma.DefineControl( "DQuestProgressBar", "", PANEL, "DPanel" )
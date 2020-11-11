local PANEL = {}

function PANEL:Init()
	self.QuestClass = ""

	self.Header 		= vgui.Create("DLabel", self)
	self.RewardTypePanel= vgui.Create("DPanel", self)
	self.RewardType 	= vgui.Create("DImage", self.RewardTypePanel)
	self.Desc 			= vgui.Create("DLabel", self)
	self.ProgressBar 	= vgui.Create("DQuestProgressBar", self)

	self.Header:SetFont("PS2_MediumLarge")
	self.Header:Dock(TOP)
	self.Header:SetContentAlignment(5)
	self.Header:SetTextColor(COLOR_WHITE)

	self.RewardTypePanel:Dock(TOP)
	self.RewardTypePanel:DockMargin(0, 8, 0, 8)
	self.RewardTypePanel:SetPaintBackground(false)
	self.RewardTypePanel:SetSize(0, 32)
	self.RewardTypePanel:SetTooltip(false)
	self.RewardType:SetSize(32, 32)
	self.RewardType:SetImage("ps-quests/icon-rand.png")

	self.Desc:SetFont("PS2_SmallHeading")
	self.Desc:Dock(FILL)
	self.Desc:SetContentAlignment(8)
	self.Desc:SetTextColor(COLOR_WHITE)

	self.ProgressBar:Dock(BOTTOM)
	self.ProgressBar:DockMargin(0, 0, 0, 8)
	self.ProgressBar:SetContentAlignment(5)

	self.ProgressBar.ProgressBar:SetSize(/*self.ProgressBar:GetWide()*/ self:GetWide() - 24 * 2, 40)
	self.ProgressBar.ProgressBar:SetPos(/*self.ProgressBar:GetWide()*/ self:GetWide() / 2 - self.ProgressBar.ProgressBar:GetWide() / 2, 0 )
	
	self.ProgressBar.ProgressLabel:SetContentAlignment(8)
	self.ProgressBar.ProgressLabel:SetTextColor(COLOR_WHITE)				
end

AccessorFunc( PANEL, "QuestClass", "QuestClass" )

function PANEL:SetHeaderText(text)
	self.Header:SetText(text)
	self.Header:SetSize(surface.GetTextSizeWithFont(text, self.Header:GetFont()))
end

function PANEL:SetDescText(text)
	self.Desc:SetText(text)
	self.Desc:SetSize(surface.GetTextSizeWithFont(text, self.Desc:GetFont()))
end

function PANEL:ApplySchemeSettings( )

end

function PANEL:PerformLayout( )

end

function PANEL:Paint()
	surface.SetDrawColor(Color(45, 45, 45))
	surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
end

derma.DefineControl( "DQuestItem", "", PANEL, "DPanel" )
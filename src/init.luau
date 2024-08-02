--!strict

local t = require(script.Parent.t)

type AttributeValidator = (...any?) -> (boolean, string?)
type AttributeFilter = (string, any?) -> boolean

local DefaultValidate = function()
	return true
end

local Attr = {}

local tGetAttribute = t.tuple(t.Instance, t.string, t.optional(t.callback), t.optional(t.any))
function Attr.GetAttribute(instance: Instance, attributeName: string, Validate: AttributeValidator?, default: any?)
	assert(tGetAttribute(instance, attributeName, Validate, default))

	local foundAttribute = instance:GetAttribute(attributeName)
	if foundAttribute == nil and (default ~= nil or Validate == nil) then
		return default
	end

	local ValidateAttribute: AttributeValidator = Validate or DefaultValidate
	local isValid: boolean, invalidReason: string? = ValidateAttribute(foundAttribute)
	assert(isValid, `Invalid Attribute "{attributeName}" found on "{instance:GetFullName()}"!\n{invalidReason}`)

	return foundAttribute
end

local tObserveAttribute = t.tuple(t.callback, t.Instance, t.string, t.optional(t.callback), t.optional(t.any))
function Attr.ObserveAttribute(
	Callback: (any?) -> (),
	instance: Instance,
	attributeName: string,
	Validate: AttributeValidator?,
	default: any?
): RBXScriptConnection
	assert(tObserveAttribute(Callback, instance, attributeName, Validate, default))

	local function OnAttributeChanged()
		Callback(Attr.GetAttribute(instance, attributeName, Validate, default))
	end
	task.defer(OnAttributeChanged)

	return instance:GetAttributeChangedSignal(attributeName):Connect(OnAttributeChanged)
end

local tGetAttributes = t.tuple(t.Instance, t.optional(t.callback))
function Attr.GetAttributes(instance: Instance, Filter: AttributeFilter?): { [string]: any }
	assert(tGetAttributes(instance, Filter))

	local attributes: { string: any } = {}
	for attributeName: string, attributeValue: any in instance:GetAttributes() do
		if Filter == nil or Filter(attributeName, attributeValue) then
			attributes[attributeName] = attributeValue
		end
	end

	return attributes
end

local tGetAttributesWithPrefix = t.tuple(t.Instance, t.string)
function Attr.GetAttributesWithPrefix(instance: Instance, prefix: string): { [string]: any }
	assert(tGetAttributesWithPrefix(instance, prefix))

	local attributes: { [string]: any } = {}
	for attributeName: string, attributeValue: any in instance:GetAttributes() do
		if string.sub(attributeName, 1, #prefix) == prefix then
			attributes[string.sub(attributeName, #prefix + 1, #attributeName)] = attributeValue
		end
	end

	return attributes
end

local tGetAttributesWithSuffix = t.tuple(t.Instance, t.string)
function Attr.GetAttributesWithSuffix(instance: Instance, suffix: string)
	assert(tGetAttributesWithSuffix(instance, suffix))

	local attributes: { [string]: any } = {}
	for attributeName: string, attributeValue: any in instance:GetAttributes() do
		if string.sub(attributeName, #attributeName - #suffix + 1, #attributeName) == suffix then
			attributes[string.sub(attributeName, 1, #attributeName - #suffix)] = attributeValue
		end
	end

	return attributes
end

local tCopyAttributes = t.tuple(t.Instance, t.Instance, t.optional(t.callback))
function Attr.CopyAttributes(fromInstance: Instance, toInstance: Instance, Filter: AttributeFilter?)
	assert(tCopyAttributes(fromInstance, toInstance, Filter))

	for attributeName: string, attributeValue: any in Attr.GetAttributes(fromInstance, Filter) do
		toInstance:SetAttribute(attributeName, attributeValue)
	end

	return toInstance
end

return Attr

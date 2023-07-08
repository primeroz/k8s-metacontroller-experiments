/*
 *
 * Copyright 2022. Metacontroller authors.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * https://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * /
 */

// +groupName=primeroz.xyz
package v1

import (
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// MqttPublisher
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +kubebuilder:subresource:status
// +kubebuilder:resource:path=mqttpublishers,scope=Namespaced
type MqttPublisher struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata"`

	Spec   MqttPublisherSpec   `json:"spec"`
	Status MqttPublisherStatus `json:"status,omitempty"`
}

type MqttPublisherSpec struct {
	topicName string `json:"topicName"`
}

type MqttPublisherStatus struct {
	observedGeneration int    `json:"observedGeneration,omitempty"`
	ready              string `json:"ready,omitempty"`
}

// MqttSubscriber
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +kubebuilder:subresource:status
// +kubebuilder:resource:path=mqttsubscribers,scope=Namespaced
type MqttSubscriber struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata"`

	Spec   MqttSubscriberSpec   `json:"spec"`
	Status MqttSubscriberStatus `json:"status,omitempty"`
}

type MqttSubscriberSpec struct {
	topicName string `json:"topicName"`
}

type MqttSubscriberStatus struct {
	observedGeneration int    `json:"observedGeneration,omitempty"`
	ready              string `json:"ready,omitempty"`
}
